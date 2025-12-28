//// Wire protocol shared with the frontend: client <-> server message types and
//// JSON helpers.
//// Those message should exist only at the frontier (server.gleam) and should
//// not navigate in the pipeline.

import chat
import gleam/dynamic/decode
import gleam/json
import gleam/time/timestamp

/// Message coming from frontend.
/// JSON must be an object with a string "type" field.
/// Missing fields or wrong types fail decoding; empty strings are accepted.
pub type ClientMessage {
  /// "chat" payload:
  /// - required: "message" (string)
  Chat(message: String)
  /// "connect" payload:
  /// - required: "token" (string), "name" (string)
  Connect(token: String, name: String)
}

/// Message sent to the frontend.
/// Encoding always emits an object with a string "type" field.
/// Clients should treat missing fields or wrong types as invalid.
pub type ServerMessage {
  /// "room_event" payload:
  /// - required: "chat.content" (string)
  /// - required: "chat.user.name" (string) or null when user is Unknown
  /// - required: "chat.timestamp.seconds" (int), "chat.timestamp.nanoseconds" (int)
  /// - never encoded: user token
  RoomEvent(chat: chat.Chat)
  /// "error" payload:
  /// - required: "message" (string)
  Error(message: String)
}

pub fn encode_server_message(message: ServerMessage) -> String {
  message
  |> server_message_json
  |> json.to_string
}

pub fn decode_client_message(
  payload: String,
) -> Result(ClientMessage, json.DecodeError) {
  json.parse(payload, client_message_decoder())
}

pub fn decode_client_messages(
  payload: String,
) -> Result(List(ClientMessage), json.DecodeError) {
  json.parse(payload, client_messages_decoder())
}

fn client_messages_decoder() -> decode.Decoder(List(ClientMessage)) {
  decode.one_of(
    decode.list(client_message_decoder()),
    or: [client_message_decoder() |> decode.map(fn(msg) { [msg] })],
  )
}

fn client_message_decoder() -> decode.Decoder(ClientMessage) {
  {
    use kind <- decode.field("type", decode.string)
    case kind {
      "chat" -> {
        use message <- decode.field("message", decode.string)
        decode.success(Chat(message))
      }
      "connect" -> {
        use token <- decode.field("token", decode.string)
        use name <- decode.field("name", decode.string)
        decode.success(Connect(token:, name:))
      }
      _ -> decode.failure(Chat(""), expected: "client message")
    }
  }
}

fn server_message_json(message: ServerMessage) -> json.Json {
  case message {
    RoomEvent(chat) ->
      json.object([
        #("type", json.string("room_event")),
        #("chat", chat_json(chat)),
      ])
    Error(message) ->
      json.object([
        #("type", json.string("error")),
        #("message", json.string(message)),
      ])
  }
}

fn chat_json(chat: chat.Chat) -> json.Json {
  let #(seconds, nanoseconds) =
    timestamp.to_unix_seconds_and_nanoseconds(chat.timestamp)

  json.object([
    #("content", json.string(chat.content)),
    #(
      "user",
      json.object([
        #("name", case chat.user {
          chat.Unknown -> json.null()
          chat.User(token: _, name:) -> json.string(name)
        }),
      ]),
    ),
    #(
      "timestamp",
      json.object([
        #("seconds", json.int(seconds)),
        #("nanoseconds", json.int(nanoseconds)),
      ]),
    ),
  ])
}
