//// Wire decoding only.

import domain/request
import gleam/dynamic/decode
import gleam/json

pub fn decode_client_messages(
  payload: String,
) -> Result(List(request.Request), json.DecodeError) {
  json.parse(payload, client_messages_decoder())
}

fn client_messages_decoder() -> decode.Decoder(List(request.Request)) {
  decode.one_of(decode.list(client_message_decoder()), or: [
    client_message_decoder() |> decode.map(fn(msg) { [msg] }),
  ])
}

fn client_message_decoder() -> decode.Decoder(request.Request) {
  {
    use kind <- decode.field("type", decode.string)
    case kind {
      "chat" -> {
        use message <- decode.field("message", decode.string)
        use room_id <- decode.field("room_id", decode.string)
        decode.success(request.Chat(message, room_id))
      }
      "connect" -> {
        use token <- decode.field("token", decode.string)
        use name <- decode.field("name", decode.string)
        decode.success(request.Connect(token:, name:))
      }
      "list_rooms" -> decode.success(request.ListRooms)
      "join_room" -> {
        use room_id <- decode.field("room_id", decode.string)
        decode.success(request.JoinRoom(room_id))
      }
      _ -> decode.failure(request.Chat("", ""), expected: "client message")
    }
  }
}
