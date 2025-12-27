import chat
import gleam/dynamic/decode
import gleam/json
import gleam/time/timestamp
import protocol

fn sample_chat(content: String) -> chat.Chat {
  chat.Chat(content, chat.User("neo"), timestamp.from_unix_seconds(1))
}

pub fn decode_client_chat_message_test() {
  let payload = "{\"type\":\"chat\",\"message\":\"hi\"}"
  let assert Ok(protocol.Chat("hi")) = protocol.decode_client_message(payload)
}

pub fn decode_client_message_unknown_type_test() {
  let payload = "{\"type\":\"noop\"}"
  let assert Error(_) = protocol.decode_client_message(payload)
}

pub fn encode_server_room_event_test() {
  let decoder =
    decode.field("type", decode.string, fn(msg_type) {
      decode.at(["chat", "content"], decode.string)
      |> decode.then(fn(content) { decode.success(#(msg_type, content)) })
    })

  let encoded =
    protocol.encode_server_message(protocol.RoomEvent(sample_chat("hey")))

  let assert Ok(#("room_event", "hey")) = json.parse(encoded, decoder)
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
