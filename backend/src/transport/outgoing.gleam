//// This message should exist only at the frontier (server.gleam) and should
//// not navigate in the pipeline.
//// This is the domain of outgoing message. It can imported and used by
//// internal packaages.

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
  ErrorMsg(message: String)

  ListRooms(rooms: List(RoomSummary))
  /// "join_room" payload:
  /// - required: "status" ("ok" or "error")
  /// - required when error: "reason" (string)
  JoinRoom(result: Result(Nil, String))
}

pub type RoomSummary {
  RoomSummary(id: String, name: String, joined: Bool)
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
    ListRooms(rooms:) ->
      json.object([
        #("type", json.string("list_rooms")),
        #(
          "rooms",
          json.array(rooms, fn(room: RoomSummary) -> json.Json {
            json.object([
              #("id", json.string(room.id)),
              #("name", json.string(room.name)),
              #("joined", json.bool(room.joined)),
            ])
          }),
        ),
      ])
    JoinRoom(result) ->
      case result {
        Ok(_) ->
          json.object([
            #("type", json.string("join_room")),
            #("status", json.string("ok")),
          ])
        Error(reason) ->
          json.object([
            #("type", json.string("join_room")),
            #("status", json.string("error")),
            #("reason", json.string(reason)),
          ])
      }
    ErrorMsg(message) ->
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
