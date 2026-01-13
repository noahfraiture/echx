//// Pipeline envelope and events.

import domain/chat
import gleam/erlang/process.{type Subject}

pub type Control {
  Subscribe(from: Subject(Envelope))
}

pub type Event {
  Chat(chat: chat.Chat, room_id: String)
}

pub type Envelope {
  Event(Event)
  Control(Control)
}
