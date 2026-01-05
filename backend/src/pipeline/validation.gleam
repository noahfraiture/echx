//// Validation stage: forwards events to listeners.

import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import pipeline/envelope
import pipeline/stage

pub type State {
  State(listeners: List(Subject(envelope.Envelope)))
}

fn handle(
  state: State,
  msg: envelope.Envelope,
) -> actor.Next(State, envelope.Envelope) {
  let State(listeners) = state
  case msg {
    envelope.Event(_) -> {
      stage.forward(listeners, msg)
      actor.continue(state)
    }
    envelope.Control(envelope.Subscribe(from)) -> {
      let listeners = stage.add_listener(listeners, from)
      actor.continue(State(listeners))
    }
  }
}

pub fn start(
  upstream: List(Subject(envelope.Envelope)),
) -> Result(Subject(envelope.Envelope), actor.StartError) {
  stage.start(State([]), upstream, handle)
}
