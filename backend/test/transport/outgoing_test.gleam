import chat
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None}
import gleam/time/timestamp
import transport/outgoing

fn sample_chat(content: String) -> chat.Chat {
  chat.Chat(
    content,
    chat.User("token-1", "Neo"),
    timestamp.from_unix_seconds(1),
  )
}

pub fn encode_server_room_event_test() {
  let decoder =
    decode.field("type", decode.string, fn(msg_type) {
      decode.at(["chat", "content"], decode.string)
      |> decode.then(fn(content) {
        decode.at(["chat", "user", "name"], decode.string)
        |> decode.then(fn(name) {
          decode.success(#(msg_type, #(content, name)))
        })
      })
    })

  let encoded =
    outgoing.encode_server_message(outgoing.RoomEvent(sample_chat("hey")))

  let assert Ok(#("room_event", #("hey", "Neo"))) = json.parse(encoded, decoder)
}

pub fn encode_server_room_event_unknown_user_test() {
  let decoder =
    decode.at(["chat", "user", "name"], decode.optional(decode.string))
  let encoded =
    outgoing.encode_server_message(
      outgoing.RoomEvent(chat.Chat(
        "hey",
        chat.Unknown,
        timestamp.from_unix_seconds(2),
      )),
    )

  let assert Ok(None) = json.parse(encoded, decoder)
}

pub fn encode_server_room_event_timestamp_fields_test() {
  let decoder =
    decode.at(["chat", "timestamp", "seconds"], decode.int)
    |> decode.then(fn(seconds) {
      decode.at(["chat", "timestamp", "nanoseconds"], decode.int)
      |> decode.then(fn(nanoseconds) { decode.success(#(seconds, nanoseconds)) })
    })

  let encoded =
    outgoing.encode_server_message(
      outgoing.RoomEvent(chat.Chat(
        "time",
        chat.User("token-1", "Neo"),
        timestamp.from_unix_seconds(42),
      )),
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
    outgoing.encode_server_message(
      outgoing.RoomEvent(chat.Chat(
        "hello",
        chat.User("secret-token", "Neo"),
        timestamp.from_unix_seconds(1),
      )),
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

  let encoded = outgoing.encode_server_message(outgoing.Error("boom"))

  let assert Ok(#("error", "boom")) = json.parse(encoded, decoder)
}
