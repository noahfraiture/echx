//// Logger stage: terminal stage that logs events.

import domain/chat
import gleam/erlang/process.{type Subject}
import gleam/json
import gleam/otp/actor
import gleam/string
import gleam/time/calendar
import gleam/time/timestamp
import logging
import pipeline/envelope
import pipeline/stage

pub type State {
  Logger
}

fn handle(
  _state: State,
  msg: envelope.Envelope,
) -> actor.Next(State, envelope.Envelope) {
  case msg {
    envelope.Event(envelope.Chat(chat, room_id)) -> {
      log_json(logging.Info, chat_event(chat, room_id))
      actor.continue(Logger)
    }
    envelope.Control(_) -> {
      log_json(logging.Error, control_event())
      actor.stop_abnormal("logger received control message")
    }
  }
}

fn log_json(level: logging.LogLevel, payload: json.Json) {
  payload
  |> json.to_string
  |> logging.log(level, _)
}

fn chat_event(chat: chat.Chat, room_id: String) -> json.Json {
  let ts = timestamp.system_time() |> timestamp.to_rfc3339(calendar.utc_offset)
  let user_name = case chat.user {
    chat.User(token: _, name:) -> json.string(name)
    chat.Unknown -> json.null()
  }

  json.object([
    #("level", json.string("info")),
    #("ts", json.string(ts)),
    #("stage", json.string("logger")),
    #("event_type", json.string("chat")),
    #("room_id", json.string(room_id)),
    #("message_id", json.string(chat.message_id)),
    #("user_name", user_name),
    #("content", json.string(chat.content)),
    #("content_len", json.int(string.length(chat.content))),
  ])
}

fn control_event() -> json.Json {
  let ts = timestamp.system_time() |> timestamp.to_rfc3339(calendar.utc_offset)
  json.object([
    #("level", json.string("error")),
    #("ts", json.string(ts)),
    #("stage", json.string("logger")),
    #("event_type", json.string("control")),
    #("message", json.string("logger received control message")),
  ])
}

pub fn start(
  upstream: List(Subject(envelope.Envelope)),
) -> Result(Subject(envelope.Envelope), actor.StartError) {
  stage.start(Logger, upstream, handle)
}
