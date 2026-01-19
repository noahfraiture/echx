//// Pipeline envelope and events.

import domain/chat
import gleam/erlang/process.{type Subject}

// Control are internal control messages between stages.
pub type Control {
  // Subscribe is a message from a stage to listen to another stage
  Subscribe(from: Subject(Envelope))
}

// Event are the actual messages that are sent between stages.
pub type Event {
  Chat(chat: chat.Chat, room_id: String)
}

pub type Envelope {
  Event(Event)
  Control(Control)
}
