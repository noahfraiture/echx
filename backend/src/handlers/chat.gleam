//// Chat request handling.

import domain/chat
import domain/response
import domain/session
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/time/timestamp
import pipeline/envelope

pub fn handle(
  pipeline: Subject(envelope.Envelope),
  state: session.Session,
  content: String,
  room_id: String,
  message_id: String,
) -> #(session.Session, response.Response) {
  let user = state.user
  actor.send(
    pipeline,
    envelope.Event(envelope.Chat(
      chat.Chat(
        content:,
        user: user,
        timestamp: timestamp.system_time(),
        message_id:,
      ),
      room_id,
    )),
  )
  #(state, response.Success)
}
