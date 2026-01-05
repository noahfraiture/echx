//// Application entrypoint wiring registry, pipeline, and transport.

import gleam/erlang/process
import logging
import pipeline/logger
import pipeline/processing
import pipeline/validation
import room_registry
import transport/server

pub fn main() {
  logging.configure()
  logging.set_level(logging.Debug)

  let registry = room_registry.new()

  let assert Ok(_) = room_registry.new_room(registry, "programming")
  let assert Ok(_) = room_registry.new_room(registry, "cinema")

  let assert Ok(validator) = validation.start([])
  let assert Ok(_processor) = processing.start([validator])
  let assert Ok(_logger) = logger.start([validator])

  let assert Ok(_) = server.new(registry, validator)

  process.sleep_forever()
}
