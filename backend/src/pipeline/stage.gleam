//// Shared helpers for pipeline stages.

import gleam/erlang/process
import gleam/list
import gleam/otp/actor
import pipeline/envelope

pub fn forward(
  listeners: List(process.Subject(envelope.Envelope)),
  msg: envelope.Envelope,
) {
  listeners
  |> list.each(fn(s: process.Subject(envelope.Envelope)) {
    process.send(s, msg)
  })
}

pub fn add_listener(
  listeners: List(process.Subject(envelope.Envelope)),
  from: process.Subject(envelope.Envelope),
) -> List(process.Subject(envelope.Envelope)) {
  [from, ..listeners]
}

pub fn start(
  initial: state,
  upstream: List(process.Subject(envelope.Envelope)),
  handler: fn(state, envelope.Envelope) -> actor.Next(state, envelope.Envelope),
) -> Result(process.Subject(envelope.Envelope), actor.StartError) {
  let assert Ok(actor.Started(_, inbox)) =
    actor.new(initial)
    |> actor.on_message(handler)
    |> actor.start

  list.each(upstream, fn(u: process.Subject(envelope.Envelope)) {
    actor.send(u, envelope.Control(envelope.Subscribe(inbox)))
  })

  Ok(inbox)
}

pub fn try_logs(
  state: state,
  msg: String,
  v: Result(a, b),
  success: fn(a) -> next,
) -> next {
  case v {
    Ok(_) -> todo
    Error(_) -> todo
  }
}
