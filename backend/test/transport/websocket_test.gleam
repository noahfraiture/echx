import domain/chat
import domain/response
import domain/session
import gleam/erlang/process
import gleam/list
import gleam/option.{None}
import gleam/otp/actor
import handlers/reply
import pipeline/envelope
import room_registry
import transport/websocket

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

pub fn list_rooms_payload_returns_reply_test() {
  let registry = setup_registry(["lobby"])
  let entry = process.new_subject()
  let state =
    session.Session(
      registry: registry,
      user: chat.User(token: "token", name: "Neo"),
      inbox: None,
      rooms: [],
    )

  let #(next_state, replies) =
    websocket.handle_payload(entry, state, "{\"type\":\"list_rooms\"}")

  assert next_state.user == state.user
  let assert [reply.Response(response.ListRooms(_))] = replies
}

pub fn chat_payload_sends_pipeline_message_test() {
  let registry = setup_registry([])
  let entry = process.new_subject()
  let state =
    session.Session(
      registry: registry,
      user: chat.User(token: "token", name: "Neo"),
      inbox: None,
      rooms: [],
    )

  let #(next_state, replies) =
    websocket.handle_payload(
      entry,
      state,
      "{\"type\":\"chat\",\"message\":\"hi\",\"room_id\":\"lobby\"}",
    )

  assert next_state.user == state.user
  assert replies == []

  let assert Ok(envelope.Event(envelope.Chat(
    chat.Chat(content: content, ..),
    "lobby",
  ))) = process.receive(entry, within: 50)
  assert content == "hi"
}

pub fn invalid_json_returns_no_reply_test() {
  let registry = setup_registry([])
  let entry = process.new_subject()
  let state =
    session.Session(
      registry: registry,
      user: chat.User(token: "token", name: "Neo"),
      inbox: None,
      rooms: [],
    )

  let #(next_state, replies) =
    websocket.handle_payload(entry, state, "not-json")

  assert next_state.user == state.user
  assert replies == []
}
