//// Room process state and commands.
//// This should not be contacted by a user directly.
//// Sent message should enter the pipeline.
//// The room registry handle room control.

import domain/chat
import domain/response
import gleam/bool
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor
import gleam/result
import gleam/set
import gleam/time/duration
import gleam/time/timestamp
import pipeline/stage

pub type RoomHandle {
  RoomHandle(id: String, name: String, command: Subject(RoomCommand))
}

// TODO : here we have response.Response but is it correct layer ?
// It works fine but it could be better maybe
pub type RoomCommand {
  Join(
    reply_to: Subject(response.Response),
    token: String,
    inbox: Subject(response.Response),
  )
  Publish(chat: chat.Chat)
  Details(reply_to: Subject(RoomDetail))
  SlowMode(reply_to: Subject(response.Response), interval: duration.Duration)
}

pub type RoomDetail {
  RoomDetail(current_size: Int, max_size: Int)
}

pub fn start(
  name: String,
  max_size: Int,
) -> Result(RoomHandle, actor.StartError) {
  actor.new(Room(
    name:,
    id: name,
    msg: [],
    clients: set.new(),
    max_size: max_size,
    interval: duration.seconds(0),
  ))
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
    clients: set.Set(Client),
    max_size: Int,
    interval: duration.Duration,
  )
}

type Client {
  Client(
    inbox: Subject(response.Response),
    token: String,
    last_sent: timestamp.Timestamp,
  )
}

fn handle_request(
  state: Room,
  msg: RoomCommand,
) -> actor.Next(Room, RoomCommand) {
  case msg {
    Join(reply_to:, token:, inbox:) -> {
      use <- bool.lazy_guard(
        state.max_size <= set.size(state.clients),
        fn() -> actor.Next(Room, RoomCommand) {
          actor.send(reply_to, response.JoinRoom(Error("no space left")))
          actor.continue(state)
        },
      )
      // use <- try_size(state, reply_to)
      let Room(clients:, ..) = state
      let client = Client(inbox:, token:, last_sent: timestamp.unix_epoch)
      actor.send(reply_to, response.Success)
      actor.continue(Room(..state, clients: set.insert(clients, client)))
    }
    Publish(chat:) -> {
      let assert chat.User(token:, name: _) = chat.user
      use now <- try_slow_mode(state, token)
      broadcast(state, chat)
      echo chat as "publish"
      let clients =
        set.map(state.clients, fn(c: Client) -> Client {
          case c.token == token {
            True -> Client(..c, last_sent: now)
            False -> c
          }
        })
      actor.continue(Room(..state, msg: [chat, ..state.msg], clients:))
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
    SlowMode(reply_to:, interval:) -> {
      actor.send(reply_to, response.Success)
      actor.continue(Room(..state, interval:))
    }
  }
}

fn try_slow_mode(
  state: Room,
  sender_token: String,
  can_send: fn(timestamp.Timestamp) -> actor.Next(Room, RoomCommand),
) -> actor.Next(Room, RoomCommand) {
  let now = timestamp.system_time()
  // Find actual client
  let sender =
    state.clients
    |> set.to_list
    |> list.find(fn(c: Client) -> Bool { c.token == sender_token })
  use sender <- stage.try_logs(state, "", sender)

  // Check it's sent long time enough
  let difference =
    sender.last_sent
    |> timestamp.add(state.interval)
    |> timestamp.difference(now)
  let #(s, ns) = duration.to_seconds_and_nanoseconds(difference)
  let ns = s * 1_000_000 + ns
  case ns > 0 {
    True -> can_send(now)
    False -> {
      actor.send(sender.inbox, response.SlowModeRejected(ns))
      actor.continue(state)
    }
  }
}

fn broadcast(state: Room, message: chat.Chat) {
  let Room(clients:, ..) = state
  clients
  |> set.each(fn(c: Client) { actor.send(c.inbox, response.RoomEvent(message)) })
}
