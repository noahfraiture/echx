//// This message should exist only at the frontier (server.gleam) and should
//// not navigate in the pipeline.

import gleam/dynamic/decode
import gleam/json

/// Message coming from frontend.
/// JSON must be an object with a string "type" field.
/// Missing fields or wrong types fail decoding; empty strings are accepted.
pub type IncomingMessage {
  /// "chat" payload:
  /// - required: "message" (string)
  Chat(message: String)
  /// "connect" payload:
  /// - required: "token" (string), "name" (string)
  Connect(token: String, name: String)
}

pub fn decode_client_messages(
  payload: String,
) -> Result(List(IncomingMessage), json.DecodeError) {
  json.parse(payload, client_messages_decoder())
}

fn client_messages_decoder() -> decode.Decoder(List(IncomingMessage)) {
  decode.one_of(decode.list(client_message_decoder()), or: [
    client_message_decoder() |> decode.map(fn(msg) { [msg] }),
  ])
}

fn client_message_decoder() -> decode.Decoder(IncomingMessage) {
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
