//// Wire encoding only.

import domain/chat
import domain/response
import gleam/json
import gleam/time/timestamp

pub fn encode_server_message(message: response.Response) -> String {
  message
  |> server_message_json
  |> json.to_string
}

fn server_message_json(message: response.Response) -> json.Json {
  case message {
    response.RoomEvent(chat) ->
      json.object([
        #("type", json.string("room_event")),
        #("chat", chat_json(chat)),
      ])
    response.ListRooms(rooms:) ->
      json.object([
        #("type", json.string("list_rooms")),
        #(
          "rooms",
          json.array(rooms, fn(room: response.RoomSummary) -> json.Json {
            json.object([
              #("id", json.string(room.id)),
              #("name", json.string(room.name)),
              #("max_size", json.int(room.max_size)),
              #("current_size", json.int(room.current_size)),
            ])
          }),
        ),
      ])
    response.JoinRoom(result) ->
      case result {
        Ok(_) ->
          json.object([
            #("type", json.string("join_room")),
            #("status", json.string("ok")),
            #("reason", json.null()),
          ])
        Error(reason) ->
          json.object([
            #("type", json.string("join_room")),
            #("status", json.string("error")),
            #("reason", json.string(reason)),
          ])
      }
    response.ErrorMsg(message) ->
      json.object([
        #("type", json.string("error")),
        #("message", json.string(message)),
      ])
    response.Unauthorized(message) ->
      json.object([
        #("type", json.string("unauthorized")),
        #("message", json.string(message)),
      ])
    response.Success ->
      json.object([
        #("type", json.string("success")),
      ])
    response.SlowModeRejected(room_id:, retry_after_ms:) -> todo
    response.SlowModeUpdate(interval_ms:) -> todo
  }
}

fn chat_json(chat: chat.Chat) -> json.Json {
  let #(seconds, nanoseconds) =
    timestamp.to_unix_seconds_and_nanoseconds(chat.timestamp)

  json.object([
    #("content", json.string(chat.content)),
    #("message_id", json.string(chat.message_id)),
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
