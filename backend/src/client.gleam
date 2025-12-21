import gleam/erlang/process.{type Subject}
import room_registry

pub type Client {
  Client(registry: Subject(room_registry.RoomRegistryMsg))
}

pub fn new(registry: Subject(room_registry.RoomRegistryMsg)) -> Client {
  Client(registry:)
}
