//// Transport-agnostic incoming request types.

/// Message coming from clients (WebSocket or REST).
pub type Request {
  Chat(message: String, room_id: String, message_id: String)
  Connect(token: String, name: String)
  ListRooms
  JoinRoom(room_id: String)
  CreateRoom(name: String, max_size: Int)
}
