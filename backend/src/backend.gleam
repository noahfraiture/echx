import gleam/erlang/process
import logging
import pipeline
import room_registry
import server

pub fn main() {
  logging.configure()
  logging.set_level(logging.Debug)

  let registry = room_registry.new()

  let assert Ok(validator) = pipeline.start_validation([])
  let assert Ok(_processor) = pipeline.start_processing([validator])
  let assert Ok(_logger) = pipeline.start_logger()

  let assert Ok(_) = server.new(registry, validator)

  process.sleep_forever()
}
