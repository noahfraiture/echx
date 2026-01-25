//// Transport-agnostic response types.

import domain/chat

/// Message sent to clients (WebSocket or REST).
pub type Response {
  RoomEvent(chat: chat.Chat)
  ErrorMsg(message: String)
  Unauthorized(message: String)
  ListRooms(rooms: List(RoomSummary))
  JoinRoom(result: Result(Nil, String))
  SlowModeRejected(retry_after: Int)
  Success
}

pub type RoomSummary {
  RoomSummary(id: String, name: String, max_size: Int, current_size: Int)
}
