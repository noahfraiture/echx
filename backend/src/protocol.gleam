//// Wire protocol shared with the frontend: client <-> server message types and
//// JSON helpers.
//// Those message should exist only at the frontier (server.gleam) and should
//// not navigate in the pipeline.

import chat
import gleam/dynamic/decode
import gleam/json
import gleam/time/timestamp

// Message coming from frontend
pub type ClientMessage {
  Chat(String)
}

// Message 
pub type ServerMessage {
  /// A room broadcast destined for a connected client.
  RoomEvent(chat: chat.Chat)
  /// A user-visible error to forward over the socket.
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

fn client_message_decoder() -> decode.Decoder(ClientMessage) {
  {
    use kind <- decode.field("type", decode.string)
    case kind {
      "chat" -> {
        use message <- decode.field("message", decode.string)
        decode.success(Chat(message))
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
    #("user", json.object([#("name", json.string(chat.user.token))])),
    #(
      "timestamp",
      json.object([
        #("seconds", json.int(seconds)),
        #("nanoseconds", json.int(nanoseconds)),
      ]),
    ),
  ])
}
