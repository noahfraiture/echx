import domain/chat

/// Message sent to clients (WebSocket or REST).
pub type Response {
  RoomEvent(chat: chat.Chat)
  ErrorMsg(message: String)
  ListRooms(rooms: List(RoomSummary))
  JoinRoom(result: Result(Nil, String))
}

pub type RoomSummary {
  RoomSummary(id: String, name: String, joined: Bool)
}
