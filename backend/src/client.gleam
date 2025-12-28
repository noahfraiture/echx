import chat
import gleam/erlang/process.{type Subject}
import room_registry

pub type Client {
  Client(registry: Subject(room_registry.RoomRegistryMsg), user: chat.User)
}
