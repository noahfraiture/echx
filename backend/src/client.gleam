import chat
import gleam/erlang/process.{type Subject}
import room_registry
import transport/outgoing

pub type Client {
  Client(
    registry: Subject(room_registry.RoomRegistryMsg),
    user: chat.User,
    inbox: Subject(outgoing.OutgoingMessage),
  )
}
