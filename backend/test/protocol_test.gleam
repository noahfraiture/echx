import chat
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None}
import gleam/time/timestamp
import protocol

fn sample_chat(content: String) -> chat.Chat {
  chat.Chat(content, chat.User("token-1", "Neo"), timestamp.from_unix_seconds(1))
}

pub fn decode_client_chat_message_test() {
  let payload = "{\"type\":\"chat\",\"message\":\"hi\"}"
  let assert Ok(protocol.Chat("hi")) = protocol.decode_client_message(payload)
}

pub fn decode_client_chat_message_missing_body_test() {
  let payload = "{\"type\":\"chat\"}"
  let assert Error(_) = protocol.decode_client_message(payload)
}

pub fn decode_client_chat_message_wrong_type_test() {
  let payload = "{\"type\":\"chat\",\"message\":42}"
  let assert Error(_) = protocol.decode_client_message(payload)
}

pub fn decode_client_connect_message_test() {
  let payload =
    "{\"type\":\"connect\",\"token\":\"token-1\",\"name\":\"Neo\"}"
  let assert Ok(protocol.Connect(token: "token-1", name: "Neo")) =
    protocol.decode_client_message(payload)
}

pub fn decode_client_connect_message_missing_token_test() {
  let payload = "{\"type\":\"connect\",\"name\":\"Neo\"}"
  let assert Error(_) = protocol.decode_client_message(payload)
}

pub fn decode_client_connect_message_missing_name_test() {
  let payload = "{\"type\":\"connect\",\"token\":\"token-1\"}"
  let assert Error(_) = protocol.decode_client_message(payload)
}

pub fn decode_client_connect_message_wrong_types_test() {
  let payload = "{\"type\":\"connect\",\"token\":false,\"name\":10}"
  let assert Error(_) = protocol.decode_client_message(payload)
}

pub fn decode_client_message_unknown_type_test() {
  let payload = "{\"type\":\"noop\"}"
  let assert Error(_) = protocol.decode_client_message(payload)
}

pub fn encode_server_room_event_test() {
  let decoder =
    decode.field("type", decode.string, fn(msg_type) {
      decode.at(["chat", "content"], decode.string)
      |> decode.then(fn(content) {
        decode.at(["chat", "user", "name"], decode.string)
        |> decode.then(fn(name) { decode.success(#(msg_type, #(content, name))) })
      })
    })

  let encoded =
    protocol.encode_server_message(protocol.RoomEvent(sample_chat("hey")))

  let assert Ok(#("room_event", #("hey", "Neo"))) = json.parse(encoded, decoder)
}

pub fn encode_server_room_event_unknown_user_test() {
  let decoder = decode.at(["chat", "user", "name"], decode.optional(decode.string))
  let encoded =
    protocol.encode_server_message(
      protocol.RoomEvent(chat.Chat("hey", chat.Unknown, timestamp.from_unix_seconds(2))),
    )

  let assert Ok(None) = json.parse(encoded, decoder)
}

pub fn encode_server_room_event_timestamp_fields_test() {
  let decoder =
    decode.at(["chat", "timestamp", "seconds"], decode.int)
    |> decode.then(fn(seconds) {
      decode.at(["chat", "timestamp", "nanoseconds"], decode.int)
      |> decode.then(fn(nanoseconds) {
        decode.success(#(seconds, nanoseconds))
      })
    })

  let encoded =
    protocol.encode_server_message(
      protocol.RoomEvent(
        chat.Chat("time", chat.User("token-1", "Neo"), timestamp.from_unix_seconds(42)),
      ),
    )

  let assert Ok(#(42, 0)) = json.parse(encoded, decoder)
}

pub fn encode_server_room_event_includes_user_name_only_test() {
  let decoder =
    decode.at(["chat", "user"], decode.dynamic)
    |> decode.then(fn(user_json) {
      let name = decode.run(user_json, decode.at(["name"], decode.string))
      let token = decode.run(user_json, decode.at(["token"], decode.string))
      decode.success(#(name, token))
    })

  let encoded =
    protocol.encode_server_message(
      protocol.RoomEvent(
        chat.Chat("hello", chat.User("secret-token", "Neo"), timestamp.from_unix_seconds(1)),
      ),
    )

  let assert Ok(#(Ok("Neo"), Error(_))) = json.parse(encoded, decoder)
}

pub fn encode_server_error_test() {
  let decoder =
    decode.field("type", decode.string, fn(msg_type) {
      decode.field("message", decode.string, fn(message) {
        decode.success(#(msg_type, message))
      })
    })

  let encoded = protocol.encode_server_message(protocol.Error("boom"))

  let assert Ok(#("error", "boom")) = json.parse(encoded, decoder)
}
