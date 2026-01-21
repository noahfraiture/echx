import domain/chat
import domain/request
import domain/response
import domain/session
import gleam/erlang/process
import gleam/list
import gleam/option
import gleam/otp/actor
import handlers/dispatch
import handlers/rooms as rooms_handler
import pipeline/room
import room_registry

fn setup_registry(
  names: List(String),
) -> process.Subject(room_registry.RoomRegistryMsg) {
  let registry = room_registry.new()
  names
  |> list.each(fn(name) {
    let assert Ok(_) =
      actor.call(registry, 50, fn(reply_to) {
        room_registry.CreateRoom(reply_to, name, 3)
      })
  })
  registry
}

pub fn join_room_requires_auth_test() {
  let registry = setup_registry(["lobby"])
  let entry = process.new_subject()
  let state =
    session.Session(
      registry: registry,
      user: chat.Unknown,
      inbox: process.new_subject(),
      rooms: [],
    )

  let #(next_state, replies) =
    dispatch.handle_requests(entry, state, [request.JoinRoom("lobby")])
  let assert [response.JoinRoom(Error(reason))] = replies
  assert reason == "unauthenticated"
  assert next_state.rooms == []
}

pub fn join_room_success_updates_state_test() {
  let registry = setup_registry(["lobby"])
  let inbox = process.new_subject()
  let state =
    session.Session(
      registry: registry,
      user: chat.User(token: "token", name: "Neo"),
      inbox: inbox,
      rooms: [],
    )

  let #(next_state, reply) = rooms_handler.join_room(state, "lobby")
  let assert response.JoinRoom(Ok(_)) = reply
  assert list.contains(next_state.rooms, "lobby")

  let assert option.Some(room.RoomHandle(id: "lobby", ..)) =
    actor.call(registry, 50, fn(reply_to) {
      room_registry.GetRoom(reply_to, "lobby")
    })
}
