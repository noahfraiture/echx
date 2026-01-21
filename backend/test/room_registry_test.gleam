import domain/response
import gleam/dict
import gleam/erlang/process
import gleam/list
import gleam/option
import gleam/otp/actor
import pipeline/room
import room_registry

pub fn list_rooms_empty_by_default_test() {
  let registry = room_registry.new()
  let response = actor.call(registry, 50, room_registry.ListRooms)

  assert [] == response
}

pub fn get_room_returns_error_when_missing_test() {
  let registry = room_registry.new()
  let response =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.GetRoom(reply_to, "missing-room")
    })

  assert option.None == response
}

pub fn rooms_can_be_added_and_retrieved_test() {
  let registry = room_registry.new()
  let assert Ok(_) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.CreateRoom(reply_to, "alpha", 2)
    })
  let assert Ok(_) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.CreateRoom(reply_to, "beta", 2)
    })

  let listed_summaries = actor.call(registry, 50, room_registry.ListRooms)
  let summary_by_id =
    listed_summaries
    |> list.fold(dict.new(), fn(acc, summary) {
      dict.insert(acc, summary.id, summary.name)
    })

  assert dict.get(summary_by_id, "alpha") == Ok("alpha")
  assert dict.get(summary_by_id, "beta") == Ok("beta")

  let assert option.Some(room.RoomHandle(id: "alpha", name: "alpha", ..)) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.GetRoom(reply_to, "alpha")
    })
  let assert option.Some(room.RoomHandle(id: "beta", name: "beta", ..)) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.GetRoom(reply_to, "beta")
    })
}

pub fn creating_a_room_twice_is_idempotent_test() {
  let registry = room_registry.new()
  let assert Ok(_) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.CreateRoom(reply_to, "alpha", 2)
    })
  let assert Ok(_) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.CreateRoom(reply_to, "alpha", 2)
    })

  let listed_summaries = actor.call(registry, 50, room_registry.ListRooms)
  assert list.length(listed_summaries) == 1

  let assert option.Some(room.RoomHandle(name: "alpha", ..)) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.GetRoom(reply_to, "alpha")
    })
}

pub fn registry_returns_real_room_handles_test() {
  let registry = room_registry.new()
  let assert Ok(_) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.CreateRoom(reply_to, "lounge", 2)
    })

  let assert option.Some(room.RoomHandle(
    id: "lounge",
    name: "lounge",
    command: command,
    max_size: 2,
    current_size: 0,
  )) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.GetRoom(reply_to, "lounge")
    })

  // Use the returned handle to prove it is live.
  let inbox = process.new_subject()
  let assert response.Success =
    actor.call(command, 50, fn(reply_to) { room.Join(reply_to, inbox) })
}
