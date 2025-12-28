import gleam/dict
import gleam/erlang/process
import gleam/list
import gleam/option
import gleam/otp/actor
import room
import room_registry

fn room_handle(id: String, name: String) -> room.RoomHandle {
  room.RoomHandle(id: id, name: name, command: process.new_subject())
}

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
      room_registry.AddRoom(reply_to, room_handle("alpha", "Alpha"))
    })
  let assert Ok(_) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.AddRoom(reply_to, room_handle("beta", "Beta"))
    })

  let listed_summaries = actor.call(registry, 50, room_registry.ListRooms)
  let summary_by_id =
    listed_summaries
    |> list.fold(dict.new(), fn(acc, summary) {
      dict.insert(acc, summary.id, summary.name)
    })

  assert dict.get(summary_by_id, "alpha") == Ok("Alpha")
  assert dict.get(summary_by_id, "beta") == Ok("Beta")

  let assert option.Some(room.RoomHandle(id: "alpha", name: "Alpha", ..)) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.GetRoom(reply_to, "alpha")
    })
  let assert option.Some(room.RoomHandle(id: "beta", name: "Beta", ..)) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.GetRoom(reply_to, "beta")
    })
}

pub fn adding_a_room_twice_returns_error_and_leaves_original_test() {
  let registry = room_registry.new()
  let assert Ok(_) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.AddRoom(reply_to, room_handle("alpha", "Alpha"))
    })
  let assert Error(Nil) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.AddRoom(reply_to, room_handle("alpha", "Changed Alpha"))
    })

  let assert option.Some(room.RoomHandle(name: "Alpha", ..)) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.GetRoom(reply_to, "alpha")
    })
}

pub fn registry_returns_real_room_handles_test() {
  let registry = room_registry.new()
  let assert Ok(handle) = room.start("lounge")

  let assert Ok(_) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.AddRoom(reply_to, handle)
    })

  let assert option.Some(room.RoomHandle(
    id: "lounge",
    name: "lounge",
    command: command,
  )) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.GetRoom(reply_to, "lounge")
    })

  // Use the returned handle to prove it is live.
  let inbox = process.new_subject()
  let assert Ok(_) =
    actor.call(command, 50, fn(reply_to) { room.Join(reply_to, inbox) })
}
