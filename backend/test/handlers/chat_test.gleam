import domain/chat
import domain/session
import gleam/erlang/process
import gleam/option.{None}
import handlers/chat as chat_handler
import pipeline/envelope

pub fn chat_sends_pipeline_message_test() {
  let entry = process.new_subject()
  let registry = process.new_subject()
  let state =
    session.Session(
      registry: registry,
      user: chat.User(token: "token", name: "Neo"),
      inbox: None,
      rooms: [],
    )

  let #(next_state, reply) = chat_handler.handle(entry, state, "hello")

  assert reply == None
  assert next_state.user == state.user

  let assert Ok(envelope.Event(envelope.Chat(chat.Chat(content: content, ..)))) =
    process.receive(entry, within: 50)
  assert content == "hello"
}
