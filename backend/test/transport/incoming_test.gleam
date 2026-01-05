import domain/request
import transport/incoming

pub fn decode_client_messages_single_object_test() {
  let payload = "{\"type\":\"chat\",\"message\":\"hi\"}"
  let assert Ok([request.Chat("hi")]) =
    incoming.decode_client_messages(payload)
}

pub fn decode_client_messages_list_test() {
  let payload =
    "[{\"type\":\"chat\",\"message\":\"hi\"},{\"type\":\"connect\",\"token\":\"token-1\",\"name\":\"Neo\"}]"
  let assert Ok([
    request.Chat("hi"),
    request.Connect(token: "token-1", name: "Neo"),
  ]) = incoming.decode_client_messages(payload)
}

pub fn decode_client_messages_empty_list_test() {
  let payload = "[]"
  let assert Ok([]) = incoming.decode_client_messages(payload)
}

pub fn decode_client_messages_list_with_invalid_entry_test() {
  let payload = "[{\"type\":\"noop\"}]"
  let assert Error(_) = incoming.decode_client_messages(payload)
}

pub fn decode_client_chat_message_missing_body_test() {
  let payload = "{\"type\":\"chat\"}"
  let assert Error(_) = incoming.decode_client_messages(payload)
}

pub fn decode_client_chat_message_wrong_type_test() {
  let payload = "{\"type\":\"chat\",\"message\":42}"
  let assert Error(_) = incoming.decode_client_messages(payload)
}

pub fn decode_client_connect_message_test() {
  let payload = "{\"type\":\"connect\",\"token\":\"token-1\",\"name\":\"Neo\"}"
  let assert Ok([request.Connect(token: "token-1", name: "Neo")]) =
    incoming.decode_client_messages(payload)
}

pub fn decode_client_connect_message_missing_token_test() {
  let payload = "{\"type\":\"connect\",\"name\":\"Neo\"}"
  let assert Error(_) = incoming.decode_client_messages(payload)
}

pub fn decode_client_connect_message_missing_name_test() {
  let payload = "{\"type\":\"connect\",\"token\":\"token-1\"}"
  let assert Error(_) = incoming.decode_client_messages(payload)
}

pub fn decode_client_connect_message_wrong_types_test() {
  let payload = "{\"type\":\"connect\",\"token\":false,\"name\":10}"
  let assert Error(_) = incoming.decode_client_messages(payload)
}

pub fn decode_client_list_rooms_message_test() {
  let payload = "{\"type\":\"list_rooms\"}"
  let assert Ok([request.ListRooms]) = incoming.decode_client_messages(payload)
}

pub fn decode_client_join_room_message_test() {
  let payload = "{\"type\":\"join_room\",\"room_id\":\"lobby\"}"
  let assert Ok([request.JoinRoom("lobby")]) =
    incoming.decode_client_messages(payload)
}

pub fn decode_client_join_room_missing_room_id_test() {
  let payload = "{\"type\":\"join_room\"}"
  let assert Error(_) = incoming.decode_client_messages(payload)
}

pub fn decode_client_message_unknown_type_test() {
  let payload = "{\"type\":\"noop\"}"
  let assert Error(_) = incoming.decode_client_messages(payload)
}
