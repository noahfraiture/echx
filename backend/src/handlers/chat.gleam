//// Chat request handling.

import domain/chat
import domain/response
import domain/session
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/time/timestamp
import handlers/reply
import pipeline/envelope

pub fn handle(
  entry: Subject(envelope.Envelope),
  state: session.Session,
  content: String,
  room_id: String,
) -> #(session.Session, reply.Reply) {
  use user <- reply.try_authentication(state)
  actor.send(
    entry,
    envelope.Event(envelope.Chat(
      chat.Chat(content:, user:, timestamp: timestamp.system_time()),
      room_id,
    )),
  )
  #(state, reply.Response(response.Success))
}
