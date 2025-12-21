import gleam/erlang/process
import logging
import room_registry
import server

pub fn main() {
  logging.configure()
  logging.set_level(logging.Debug)

  let registry = room_registry.new()

  let assert Ok(_) = server.new(registry)

  process.sleep_forever()
}
