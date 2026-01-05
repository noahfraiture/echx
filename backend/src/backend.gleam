import gleam/erlang/process
import logging
import pipeline
import room_registry
import transport/server

pub fn main() {
  logging.configure()
  logging.set_level(logging.Debug)

  let registry = room_registry.new()

  let assert Ok(_) = room_registry.new_room(registry, "programming")
  let assert Ok(_) = room_registry.new_room(registry, "cinema")

  let assert Ok(validator) = pipeline.start_validation([])
  let assert Ok(_processor) = pipeline.start_processing([validator])
  let assert Ok(_logger) = pipeline.start_logger([validator])

  let assert Ok(_) = server.new(registry, validator)

  process.sleep_forever()
}
