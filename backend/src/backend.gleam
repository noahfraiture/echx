//// Application entrypoint wiring registry, pipeline, and transport.

import gleam/erlang/process
import logging
import pipeline/stage_logger
import pipeline/stage_processing
import pipeline/stage_validation
import room_registry
import transport/server

pub fn main() {
  logging.configure()
  logging.set_level(logging.Debug)

  let registry = room_registry.new()

  let assert Ok(_) = room_registry.new_room(registry, "programming", 5)
  let assert Ok(_) = room_registry.new_room(registry, "cinema", 5)

  let assert Ok(validator) = stage_validation.start([])
  let assert Ok(_processor) = stage_processing.start([validator], registry)
  let assert Ok(_logger) = stage_logger.start([validator])

  let assert Ok(_) = server.new(registry, validator)

  process.sleep_forever()
}
