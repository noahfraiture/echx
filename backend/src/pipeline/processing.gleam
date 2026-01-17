//// Processing stage: forwards events to listeners.

import gleam/erlang/process.{type Subject}
import gleam/option.{Some}
import gleam/otp/actor
import pipeline/envelope
import pipeline/stage
import room
import room_registry

pub type State {
  State(
    listeners: List(Subject(envelope.Envelope)),
    registry: Subject(room_registry.RoomRegistryMsg),
  )
}

fn handle(
  state: State,
  msg: envelope.Envelope,
) -> actor.Next(State, envelope.Envelope) {
  let State(listeners, registry) = state
  case msg {
    envelope.Event(envelope.Chat(chat, room_id)) -> {
      let room_handler =
        actor.call(registry, 1000, room_registry.GetRoom(_, room_id))
      case room_handler {
        Some(room_handle) -> {
          actor.send(room_handle.command, room.Publish(chat))
          stage.forward(listeners, msg)
        }
        _ -> Nil
      }
      actor.continue(state)
    }
    envelope.Control(envelope.Subscribe(from)) -> {
      let listeners = stage.add_listener(listeners, from)
      actor.continue(State(..state, listeners:))
    }
  }
}

pub fn start(
  upstream: List(Subject(envelope.Envelope)),
  registry: Subject(room_registry.RoomRegistryMsg),
) -> Result(Subject(envelope.Envelope), actor.StartError) {
  stage.start(State([], registry:), upstream, handle)
}
