/// Message coming from clients (WebSocket or REST).
pub type Request {
  Chat(message: String)
  Connect(token: String, name: String)
  ListRooms
  JoinRoom(room_id: String)
}
