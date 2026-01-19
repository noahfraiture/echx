//// Session and REST context state.

import domain/chat
import domain/response
import gleam/erlang/process.{type Subject}
import room_registry

pub type Session {
  /// Per-connection state used by handlers.
  /// - WebSocket: `inbox` is required, `rooms` tracks joined rooms.
  Session(
    registry: Subject(room_registry.RoomRegistryMsg),
    user: chat.User,
    inbox: Subject(response.Response),
    rooms: List(String),
  )
}
