//// Room registry process for listing and creating rooms.

import domain/response
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject, new_subject, send_after}
import gleam/list
import gleam/option.{type Option}
import gleam/order
import gleam/otp/actor
import gleam/time/duration
import gleam/time/timestamp
import pipeline/room

/// Hub where rooms are registered
type RoomRegistry {
  RoomRegistry(
    rooms: Dict(String, room.RoomHandle),
    registry: Subject(RoomRegistryMsg),
  )
}

pub type RoomRegistryMsg {
  ListRooms(reply_to: Subject(List(response.RoomSummary)))
  GetRoom(reply_to: Subject(Option(room.RoomHandle)), id: String)
  CreateRoom(reply_to: Subject(Result(Nil, Nil)), name: String, max_user: Int)
  Sweep
}

fn handle(
  state: RoomRegistry,
  msg: RoomRegistryMsg,
) -> actor.Next(RoomRegistry, RoomRegistryMsg) {
  let RoomRegistry(rooms:, registry: _) = state
  case msg {
    ListRooms(reply_to:) -> {
      let summaries =
        dict.values(rooms)
        |> list.map(fn(handle: room.RoomHandle) {
          let details = actor.call(handle.command, 1000, room.Details)
          response.RoomSummary(
            id: handle.id,
            name: handle.name,
            max_size: details.max_size,
            current_size: details.current_size,
          )
        })
      actor.send(reply_to, summaries)
      actor.continue(state)
    }
    GetRoom(reply_to:, id:) -> {
      actor.send(reply_to, option.from_result(dict.get(rooms, id)))
      actor.continue(state)
    }
    CreateRoom(reply_to:, name:, max_user:) ->
      handle_create_room(state, reply_to, name, max_user, rooms)
    Sweep -> handle_sweep(state)
  }
}

fn handle_create_room(
  state: RoomRegistry,
  reply_to: Subject(Result(Nil, Nil)),
  name: String,
  max_user: Int,
  rooms: Dict(String, room.RoomHandle),
) {
  case dict.has_key(state.rooms, name) {
    False -> {
      case room.start(name, max_user) {
        Error(_) -> {
          actor.send(reply_to, Error(Nil))
          actor.continue(state)
        }
        Ok(handle) -> {
          actor.send(reply_to, Ok(Nil))
          actor.continue(RoomRegistry(
            dict.insert(rooms, name, handle),
            registry: state.registry,
          ))
        }
      }
    }
    True -> {
      actor.send(reply_to, Ok(Nil))
      actor.continue(state)
    }
  }
}

pub fn new_room(
  registry: Subject(RoomRegistryMsg),
  name: String,
  max_user: Int,
) -> Result(Nil, Nil) {
  actor.call(registry, 1000, CreateRoom(_, name, max_user))
}

pub fn new() -> Subject(RoomRegistryMsg) {
  let assert Ok(actor.Started(_, registry)) =
    actor.new_with_initialiser(1000, fn(subject) {
      actor.initialised(RoomRegistry(rooms: dict.new(), registry: subject))
      |> actor.returning(subject)
      |> Ok
    })
    |> actor.on_message(handle)
    |> actor.start
  schedule_sweep(registry)
  registry
}

fn handle_sweep(
  state: RoomRegistry,
) -> actor.Next(RoomRegistry, RoomRegistryMsg) {
  let now = timestamp.system_time()
  let cutoff = timestamp.add(now, duration.hours(-24))
  let stale =
    state.rooms
    |> dict.values
    |> list.filter(fn(handle: room.RoomHandle) {
      let details = actor.call(handle.command, 1000, room.Details)
      details.current_size == 0
      && timestamp.compare(details.last_sent, cutoff) == order.Lt
    })

  stale
  |> list.each(fn(handle: room.RoomHandle) {
    actor.send(handle.command, room.Stop)
  })

  let rooms =
    stale
    |> list.map(fn(handle: room.RoomHandle) { handle.id })
    |> list.fold(state.rooms, fn(rooms, id) { dict.delete(rooms, id) })

  schedule_sweep(state.registry)
  actor.continue(RoomRegistry(rooms, registry: state.registry))
}

fn schedule_sweep(registry: Subject(RoomRegistryMsg)) {
  send_after(registry, 3_600_000, Sweep)
  Nil
}
