//// This message should exist only at the frontier (server.gleam) and should
//// not navigate in the pipeline.

import chat
import gleam/json
import gleam/time/timestamp

/// Message sent to the frontend.
/// Encoding always emits an object with a string "type" field.
/// Clients should treat missing fields or wrong types as invalid.
pub type OutgoingMessage {
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

pub fn encode_server_message(message: OutgoingMessage) -> String {
  message
  |> server_message_json
  |> json.to_string
}

fn server_message_json(message: OutgoingMessage) -> json.Json {
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
