import domain/chat
import domain/request
import domain/response
import domain/session
import gleam/erlang/process
import gleam/list

import gleam/otp/actor
import handlers/dispatch
import pipeline/envelope
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

pub fn handle_request_connect_sets_user_test() {
  let entry = process.new_subject()
  let registry = process.new_subject()
  let state =
    session.Session(
      registry: registry,
      user: chat.Unknown,
      inbox: process.new_subject(),
      rooms: [],
    )

  let #(next_state, reply) =
    dispatch.handle_request(
      entry,
      state,
      request.Connect(token: "token", name: "Neo"),
    )

  let assert chat.User(token: "token", name: "Neo") = next_state.user
  assert reply == response.Success
}

pub fn handle_request_connect_updates_name_test() {
  let entry = process.new_subject()
  let registry = process.new_subject()
  let state =
    session.Session(
      registry: registry,
      user: chat.User(token: "token", name: "Neo"),
      inbox: process.new_subject(),
      rooms: [],
    )

  let #(next_state, reply) =
    dispatch.handle_request(
      entry,
      state,
      request.Connect(token: "token", name: "Trinity"),
    )

  let assert chat.User(token: "token", name: "Trinity") = next_state.user
  assert reply == response.Success
}

pub fn handle_requests_collects_replies_test() {
  let entry = process.new_subject()
  let registry = setup_registry(["lobby"])
  let state =
    session.Session(
      registry: registry,
      user: chat.User(token: "token", name: "Neo"),
      inbox: process.new_subject(),
      rooms: [],
    )

  let #(next_state, replies) =
    dispatch.handle_requests(entry, state, [request.ListRooms])

  assert next_state.user == state.user
  let assert [response.ListRooms(_)] = replies
}

pub fn handle_requests_chat_has_no_reply_test() {
  let entry = process.new_subject()
  let registry = process.new_subject()
  let state =
    session.Session(
      registry: registry,
      user: chat.User(token: "token", name: "Neo"),
      inbox: process.new_subject(),
      rooms: [],
    )

  let #(next_state, replies) =
    dispatch.handle_requests(entry, state, [request.Chat("hello", "", "msg-1")])

  assert next_state.user == state.user
  let assert [response.Success] = replies

  let assert Ok(envelope.Event(envelope.Chat(
    chat.Chat(content: content, message_id: message_id, ..),
    "",
  ))) = process.receive(entry, within: 50)
  assert content == "hello"
  assert message_id == "msg-1"
}
