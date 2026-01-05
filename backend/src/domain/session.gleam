import domain/chat
import domain/response
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option}
import room_registry

pub type Session {
  /// Per-connection state used by handlers.
  /// - WebSocket: `inbox` is Some, `rooms` is maintained as the client joins.
  /// - REST: `inbox` is None and `rooms` is empty per request.
  Session(
    registry: Subject(room_registry.RoomRegistryMsg),
    user: chat.User,
    inbox: Option(Subject(response.Response)),
    rooms: List(String),
  )
}

pub type Context {
  /// Per-request auth context for REST handlers.
  /// The transport builds a Session from this when dispatching a JSON request.
  Context(
    registry: Option(Subject(room_registry.RoomRegistryMsg)),
    user: Option(chat.User),
  )
}
