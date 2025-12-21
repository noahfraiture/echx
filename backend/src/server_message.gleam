//// Messages emitted by server processes toward a connection inbox.

import chat

pub type ServerMessage {
  /// A room broadcast destined for a connected client.
  RoomEvent(chat: chat.Chat)
  /// A user-visible error to forward over the socket.
  Error(message: String)
}
