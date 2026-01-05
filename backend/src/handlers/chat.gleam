import domain/chat
import domain/session
import gleam/erlang/process.{type Subject}
import gleam/option.{type Option, None}
import gleam/time/timestamp
import gleam/otp/actor
import handlers/reply
import pipeline

pub fn handle(
  entry: Subject(pipeline.Message),
  state: session.Session,
  content: String,
) -> #(session.Session, Option(reply.Reply)) {
  actor.send(
    entry,
    pipeline.Chat(chat.Chat(
      content:,
      user: state.user,
      timestamp: timestamp.system_time(),
    )),
  )
  #(state, None)
}
