//// Transport-agnostic response types.

import domain/chat

/// Message sent to clients (WebSocket or REST).
pub type Response {
  RoomEvent(chat: chat.Chat)
  ErrorMsg(message: String)
  ListRooms(rooms: List(RoomSummary))
  JoinRoom(result: Result(Nil, String))
}

pub type RoomSummary {
  /// `joined` is only meaningful for WebSocket clients.
  RoomSummary(id: String, name: String, joined: Bool)
}
