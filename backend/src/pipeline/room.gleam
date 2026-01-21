//// Room process state and commands.
//// This should not be contacted by a user directly.
//// Sent message should enter the pipeline.
//// The room registry handle room control.

import domain/chat
import domain/response
import gleam/erlang/process.{type Subject}
import gleam/otp/actor
import gleam/result
import gleam/set

pub type RoomHandle {
  RoomHandle(id: String, name: String, command: Subject(RoomCommand))
}

pub type RoomCommand {
  Join(reply_to: Subject(response.Response), inbox: Subject(response.Response))
  Publish(chat: chat.Chat)
  Details(reply_to: Subject(RoomDetail))
}

pub type RoomDetail {
  RoomDetail(current_size: Int, max_size: Int)
}

pub fn start(
  name: String,
  max_size: Int,
) -> Result(RoomHandle, actor.StartError) {
  actor.new(Room(name:, id: name, msg: [], clients: set.new(), max_size:))
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
    clients: set.Set(Subject(response.Response)),
    max_size: Int,
  )
}

fn handle_request(
  state: Room,
  msg: RoomCommand,
) -> actor.Next(Room, RoomCommand) {
  case msg {
    Join(reply_to:, inbox:) -> {
      use <- try_size(state, reply_to)
      let Room(clients:, ..) = state
      actor.send(reply_to, response.Success)
      actor.continue(Room(..state, clients: set.insert(clients, inbox)))
    }
    Publish(chat) -> {
      broadcast(state, chat)
      echo chat as "publish"
      actor.continue(Room(..state, msg: [chat, ..state.msg]))
    }
    Details(reply_to:) -> {
      actor.send(
        reply_to,
        RoomDetail(
          current_size: set.size(state.clients),
          max_size: state.max_size,
        ),
      )
      actor.continue(state)
    }
  }
}

fn try_size(
  state: Room,
  reply_to: Subject(response.Response),
  space_left: fn() -> actor.Next(Room, RoomCommand),
) -> actor.Next(Room, RoomCommand) {
  case state.max_size > set.size(state.clients) {
    True -> space_left()
    False -> {
      actor.send(reply_to, response.JoinRoom(Error("no space left")))
      actor.continue(state)
    }
  }
}

fn broadcast(state: Room, message: chat.Chat) {
  let Room(clients:, ..) = state
  clients
  |> set.each(fn(c: Subject(response.Response)) {
    actor.send(c, response.RoomEvent(message))
  })
}
