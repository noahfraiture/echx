import domain/chat
import gleam/bit_array
import gleam/bytes_tree
import gleam/dynamic/decode
import gleam/erlang/process
import gleam/http/response as http_response
import gleam/json
import gleam/list
import gleam/otp/actor
import mist
import pipeline/envelope
import room_registry
import transport/rest

fn setup_registry(names: List(String)) -> process.Subject(room_registry.RoomRegistryMsg) {
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

fn response_body_string(
  resp: http_response.Response(mist.ResponseData),
) -> Result(String, Nil) {
  let http_response.Response(body: body, ..) = resp
  case body {
    mist.Bytes(tree) ->
      tree
      |> bytes_tree.to_bit_array
      |> bit_array.to_string
    _ -> Error(Nil)
  }
}

pub fn list_rooms_payload_returns_json_test() {
  let registry = setup_registry(["lobby"])
  let entry = process.new_subject()
  let resp =
    rest.handle_payload(
      registry,
      chat.User(token: "token", name: "Neo"),
      entry,
      "{\"type\":\"list_rooms\"}",
    )

  let http_response.Response(status: status, ..) = resp
  assert status == 200

  let assert Ok(body) = response_body_string(resp)
  let decoder =
    decode.field("type", decode.string, fn(msg_type) {
      decode.success(msg_type)
    })
  let assert Ok("list_rooms") = json.parse(body, decoder)
}

pub fn chat_payload_sends_pipeline_message_test() {
  let registry = setup_registry([])
  let entry = process.new_subject()
  let resp =
    rest.handle_payload(
      registry,
      chat.User(token: "token", name: "Neo"),
      entry,
      "{\"type\":\"chat\",\"message\":\"hi\"}",
    )

  let http_response.Response(status: status, ..) = resp
  assert status == 204

  let assert Ok(envelope.Event(envelope.Chat(chat.Chat(content: content, ..)))) =
    process.receive(entry, within: 50)
  assert content == "hi"
}

pub fn join_room_payload_without_inbox_returns_error_test() {
  let registry = setup_registry(["lobby"])
  let entry = process.new_subject()
  let resp =
    rest.handle_payload(
      registry,
      chat.User(token: "token", name: "Neo"),
      entry,
      "{\"type\":\"join_room\",\"room_id\":\"lobby\"}",
    )

  let http_response.Response(status: status, ..) = resp
  assert status == 200

  let assert Ok(body) = response_body_string(resp)
  let decoder =
    decode.field("type", decode.string, fn(msg_type) {
      decode.field("status", decode.string, fn(status) {
        decode.field("reason", decode.string, fn(reason) {
          decode.success(#(msg_type, #(status, reason)))
        })
      })
    })

  let assert Ok(#("join_room", #("error", reason))) =
    json.parse(body, decoder)
  assert reason == "no inbox available"
}

pub fn invalid_json_returns_error_test() {
  let registry = setup_registry([])
  let entry = process.new_subject()
  let resp =
    rest.handle_payload(
      registry,
      chat.User(token: "token", name: "Neo"),
      entry,
      "not-json",
    )

  let http_response.Response(status: status, ..) = resp
  assert status == 400

  let assert Ok(body) = response_body_string(resp)
  let decoder =
    decode.field("type", decode.string, fn(msg_type) {
      decode.field("message", decode.string, fn(message) {
        decode.success(#(msg_type, message))
      })
    })
  let assert Ok(#("error", "invalid json")) = json.parse(body, decoder)
}
