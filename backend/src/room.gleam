import chat
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/result
import gleam/set
import transport/outgoing

pub type RoomHandle {
  RoomHandle(id: String, name: String, command: Subject(RoomCommand))
}

pub type JoinResult =
  Result(Nil, Nil)

pub type RoomCommand {
  Join(reply_to: Subject(JoinResult), inbox: Subject(outgoing.OutgoingMessage))
  Publish(chat: chat.Chat)
}

pub fn start(name: String) -> Result(RoomHandle, actor.StartError) {
  actor.new(Room(name:, id: name, msg: [], clients: set.new()))
  |> actor.on_message(handle_request)
  |> actor.start
  |> result.map(fn(a: actor.Started(Subject(RoomCommand))) {
    RoomHandle(name, name, a.data)
  })
}

type Room {
  Room(
    name: String,
    id: String,
    msg: List(chat.Chat),
    clients: set.Set(Subject(outgoing.OutgoingMessage)),
  )
}

fn handle_request(
  state: Room,
  msg: RoomCommand,
) -> actor.Next(Room, RoomCommand) {
  case msg {
    Join(reply_to:, inbox:) -> {
      let Room(clients:, ..) = state
      actor.send(reply_to, Ok(Nil))
      actor.continue(Room(..state, clients: set.insert(clients, inbox)))
    }
    Publish(chat) -> {
      broadcast(state, chat)
      actor.continue(Room(..state, msg: [chat, ..state.msg]))
    }
  }
}

fn broadcast(state: Room, message: chat.Chat) {
  let Room(clients:, ..) = state
  clients
  |> set.each(fn(c: Subject(outgoing.OutgoingMessage)) {
    actor.send(c, outgoing.RoomEvent(message))
  })
}
