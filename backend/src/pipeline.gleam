import domain/chat
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor

pub opaque type Pipeline {
  Validation(listeners: List(Subject(Message)))
  Processing(listeners: List(Subject(Message)))
  Logger
}

pub type PipelineError {
  ValidationError
}

pub type Message {
  Chat(chat.Chat)
  Subscribe(from: Subject(Message))
}

fn forward(listeners: List(Subject(Message)), msg: Message) {
  listeners
  |> list.each(fn(s: Subject(Message)) { process.send(s, msg) })
}

fn handle_chat(state: Pipeline, msg: Message) -> Pipeline {
  case state {
    Logger -> {
      state
    }

    Processing(listeners) -> {
      forward(listeners, msg)
      state
    }

    Validation(listeners) -> {
      forward(listeners, msg)
      state
    }
  }
}

fn add_listener(state: Pipeline, from: Subject(Message)) -> Pipeline {
  case state {
    Logger -> Logger

    Processing(listeners) -> Processing([from, ..listeners])

    Validation(listeners) -> Validation([from, ..listeners])
  }
}

fn handle(state: Pipeline, msg: Message) -> actor.Next(Pipeline, Message) {
  case msg {
    Chat(_) -> {
      let state = handle_chat(state, msg)
      actor.continue(state)
    }

    Subscribe(from) -> {
      let state = add_listener(state, from)
      actor.continue(state)
    }
  }
}

pub fn start_validation(
  upstream: List(Subject(Message)),
) -> Result(Subject(Message), actor.StartError) {
  start_stage(Validation([]), upstream)
}

pub fn start_processing(
  upstream: List(Subject(Message)),
) -> Result(Subject(Message), actor.StartError) {
  start_stage(Processing([]), upstream)
}

pub fn start_logger(
  upstream: List(Subject(Message)),
) -> Result(Subject(Message), actor.StartError) {
  start_stage(Logger, upstream)
}

// Shared starter for any stage.
fn start_stage(
  initial: Pipeline,
  upstream: List(Subject(Message)),
) -> Result(Subject(Message), actor.StartError) {
  let assert Ok(actor.Started(_, inbox)) =
    actor.new(initial)
    |> actor.on_message(handle)
    |> actor.start

  list.each(upstream, fn(u: Subject(Message)) {
    actor.send(u, Subscribe(inbox))
  })

  Ok(inbox)
}
