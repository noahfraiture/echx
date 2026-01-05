//// Logger stage: terminal stage that ignores events.

import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import pipeline/envelope
import pipeline/stage

pub type State {
  Logger
}

fn handle(
  _state: State,
  _msg: envelope.Envelope,
) -> actor.Next(State, envelope.Envelope) {
  actor.continue(Logger)
}

pub fn start(
  upstream: List(Subject(envelope.Envelope)),
) -> Result(Subject(envelope.Envelope), actor.StartError) {
  stage.start(Logger, upstream, handle)
}
