import chat
import gleam/erlang/process
import gleam/otp/actor
import gleam/time/timestamp
import transport/outgoing
import room

fn sample_chat(content: String) -> chat.Chat {
  chat.Chat(
    content,
    chat.User(token: "user-token", name: "user"),
    timestamp.from_unix_seconds(0),
  )
}

pub fn join_deduplicates_members_test() {
  let assert Ok(handle) = room.start("duplicates")
  let inbox = process.new_subject()
  let other = process.new_subject()

  let assert Ok(_) =
    actor.call(handle.command, 50, fn(reply_to) { room.Join(reply_to, inbox) })
  let assert Ok(_) =
    actor.call(handle.command, 50, fn(reply_to) { room.Join(reply_to, inbox) })
  let assert Ok(_) =
    actor.call(handle.command, 50, fn(reply_to) { room.Join(reply_to, other) })

  actor.send(handle.command, room.Publish(sample_chat("hello")))

  let assert Ok(outgoing.RoomEvent(chat: first)) =
    process.receive(inbox, within: 50)
  assert first.content == "hello"
  assert Error(Nil) == process.receive(inbox, within: 20)

  let assert Ok(outgoing.RoomEvent(chat: second)) =
    process.receive(other, within: 50)
  assert second.content == "hello"
}

pub fn publish_sends_to_all_members_test() {
  let assert Ok(handle) = room.start("broadcast")
  let alice = process.new_subject()
  let bob = process.new_subject()

  let assert Ok(_) =
    actor.call(handle.command, 50, fn(reply_to) { room.Join(reply_to, alice) })
  let assert Ok(_) =
    actor.call(handle.command, 50, fn(reply_to) { room.Join(reply_to, bob) })

  actor.send(handle.command, room.Publish(sample_chat("hi all")))

  let assert Ok(outgoing.RoomEvent(chat: alice_msg)) =
    process.receive(alice, within: 50)
  let assert Ok(outgoing.RoomEvent(chat: bob_msg)) =
    process.receive(bob, within: 50)

  assert alice_msg.content == "hi all"
  assert bob_msg.content == "hi all"
}

pub fn publish_is_noop_when_empty_test() {
  let assert Ok(handle) = room.start("empty")
  actor.send(handle.command, room.Publish(sample_chat("still here")))

  let inbox = process.new_subject()
  let assert Ok(_) =
    actor.call(handle.command, 50, fn(reply_to) { room.Join(reply_to, inbox) })
}
