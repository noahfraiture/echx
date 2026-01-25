import domain/chat
import domain/response
import gleam/erlang/process
import gleam/otp/actor
import gleam/time/duration
import gleam/time/timestamp
import pipeline/room

fn sample_chat(content: String) -> chat.Chat {
  chat.Chat(
    content,
    chat.User(token: "user-token", name: "user"),
    timestamp.from_unix_seconds(0),
    "msg-" <> content,
  )
}

pub fn join_deduplicates_members_test() {
  let assert Ok(handle) = room.start("duplicates", 3)
  let inbox = process.new_subject()
  let other = process.new_subject()

  let assert response.Success =
    actor.call(handle.command, 50, fn(reply_to) {
      room.Join(reply_to, "user-token", inbox)
    })
  let assert response.Success =
    actor.call(handle.command, 50, fn(reply_to) {
      room.Join(reply_to, "user-token", inbox)
    })
  let assert response.Success =
    actor.call(handle.command, 50, fn(reply_to) {
      room.Join(reply_to, "other-token", other)
    })

  actor.send(handle.command, room.Publish(sample_chat("hello")))

  let assert Ok(response.RoomEvent(chat: first)) =
    process.receive(inbox, within: 50)
  assert first.content == "hello"
  assert first.message_id == "msg-hello"
  assert Error(Nil) == process.receive(inbox, within: 20)

  let assert Ok(response.RoomEvent(chat: second)) =
    process.receive(other, within: 50)
  assert second.content == "hello"
  assert second.message_id == "msg-hello"
}

pub fn publish_sends_to_all_members_test() {
  let assert Ok(handle) = room.start("broadcast", 2)
  let alice = process.new_subject()
  let bob = process.new_subject()

  let assert response.Success =
    actor.call(handle.command, 50, fn(reply_to) {
      room.Join(reply_to, "user-token", alice)
    })
  let assert response.Success =
    actor.call(handle.command, 50, fn(reply_to) {
      room.Join(reply_to, "user-token", bob)
    })

  actor.send(handle.command, room.Publish(sample_chat("hi all")))

  let assert Ok(response.RoomEvent(chat: alice_msg)) =
    process.receive(alice, within: 50)
  let assert Ok(response.RoomEvent(chat: bob_msg)) =
    process.receive(bob, within: 50)

  assert alice_msg.content == "hi all"
  assert alice_msg.message_id == "msg-hi all"
  assert bob_msg.content == "hi all"
  assert bob_msg.message_id == "msg-hi all"
}

pub fn publish_is_noop_when_empty_test() {
  let assert Ok(handle) = room.start("empty", 2)
  actor.send(handle.command, room.Publish(sample_chat("still here")))

  let inbox = process.new_subject()
  let assert response.Success =
    actor.call(handle.command, 50, fn(reply_to) {
      room.Join(reply_to, "late-joiner", inbox)
    })
}

pub fn slow_mode_rejects_second_message_test() {
  let assert Ok(handle) = room.start("slow-mode", 2)
  let inbox = process.new_subject()

  let assert response.Success =
    actor.call(handle.command, 50, fn(reply_to) {
      room.Join(reply_to, "user-token", inbox)
    })
  let assert response.Success =
    actor.call(handle.command, 50, fn(reply_to) {
      room.SlowMode(reply_to, duration.seconds(5))
    })

  actor.send(handle.command, room.Publish(sample_chat("first")))
  let assert Ok(response.RoomEvent(chat: first)) =
    process.receive(inbox, within: 50)
  assert first.message_id == "msg-first"

  actor.send(handle.command, room.Publish(sample_chat("second")))
  let assert Ok(response.SlowModeRejected(retry_after: retry_after)) =
    process.receive(inbox, within: 50)
  assert retry_after > 0
}

pub fn slow_mode_allows_after_interval_test() {
  let assert Ok(handle) = room.start("slow-interval", 2)
  let inbox = process.new_subject()

  let assert response.Success =
    actor.call(handle.command, 50, fn(reply_to) {
      room.Join(reply_to, "user-token", inbox)
    })
  let assert response.Success =
    actor.call(handle.command, 50, fn(reply_to) {
      room.SlowMode(reply_to, duration.seconds(0))
    })

  actor.send(handle.command, room.Publish(sample_chat("first")))
  let assert Ok(response.RoomEvent(chat: first)) =
    process.receive(inbox, within: 50)
  assert first.message_id == "msg-first"

  actor.send(handle.command, room.Publish(sample_chat("second")))
  let assert Ok(response.RoomEvent(chat: second)) =
    process.receive(inbox, within: 50)
  assert second.message_id == "msg-second"
}
