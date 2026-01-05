//// Chat request handling.

import domain/chat
import domain/session
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None}
import gleam/otp/actor
import gleam/time/timestamp
import handlers/reply
import pipeline/envelope

pub fn handle(
  entry: Subject(envelope.Envelope),
  state: session.Session,
  content: String,
) -> #(session.Session, Option(reply.Reply)) {
  actor.send(
    entry,
    envelope.Event(
      envelope.Chat(chat.Chat(
        content:,
        user: state.user,
        timestamp: timestamp.system_time(),
      )),
    ),
  )
  #(state, None)
}
