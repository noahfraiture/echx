import domain/chat
import domain/response
import domain/session
import gleam/erlang/process
import gleam/list
import gleam/option.{None, Some}
import gleam/otp/actor
import handlers/reply
import handlers/rooms as rooms_handler
import room
import room_registry

fn setup_registry(
  names: List(String),
) -> process.Subject(room_registry.RoomRegistryMsg) {
  let registry = room_registry.new()
  names
  |> list.each(fn(name) {
    let assert Ok(_) =
      actor.call(registry, 50, fn(reply_to) {
        room_registry.CreateRoom(reply_to, name)
      })
  })
  registry
}

pub fn list_rooms_marks_joined_test() {
  let registry = setup_registry(["lobby", "games"])
  let state =
    session.Session(
      registry: registry,
      user: chat.User(token: "token", name: "Neo"),
      inbox: None,
      rooms: ["lobby"],
    )

  let reply = rooms_handler.list_rooms(state)
  let assert reply.Response(response.ListRooms(rooms)) = reply

  let assert Ok(lobby) = list.find(rooms, fn(room) { room.id == "lobby" })
  let assert Ok(games) = list.find(rooms, fn(room) { room.id == "games" })

  assert lobby.joined == True
  assert games.joined == False
}

pub fn join_room_requires_auth_test() {
  let registry = setup_registry(["lobby"])
  let state =
    session.Session(
      registry: registry,
      user: chat.Unknown,
      inbox: None,
      rooms: [],
    )

  let #(next_state, reply) = rooms_handler.join_room(state, "lobby")
  let assert reply.Response(response.JoinRoom(Error(reason))) = reply
  assert reason == "unauthenticated"
  assert next_state.rooms == []
}

pub fn join_room_requires_inbox_test() {
  let registry = setup_registry(["lobby"])
  let state =
    session.Session(
      registry: registry,
      user: chat.User(token: "token", name: "Neo"),
      inbox: None,
      rooms: [],
    )

  let #(next_state, reply) = rooms_handler.join_room(state, "lobby")
  let assert reply.Response(response.JoinRoom(Error(reason))) = reply
  assert reason == "no inbox available"
  assert next_state.rooms == []
}

pub fn join_room_success_updates_state_test() {
  let registry = setup_registry(["lobby"])
  let inbox = process.new_subject()
  let state =
    session.Session(
      registry: registry,
      user: chat.User(token: "token", name: "Neo"),
      inbox: Some(inbox),
      rooms: [],
    )

  let #(next_state, reply) = rooms_handler.join_room(state, "lobby")
  let assert reply.Response(response.JoinRoom(Ok(_))) = reply
  assert list.contains(next_state.rooms, "lobby")

  let assert option.Some(room.RoomHandle(id: "lobby", ..)) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.GetRoom(reply_to, "lobby")
    })
}
