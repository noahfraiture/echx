//// Room registry process for listing and creating rooms.

import domain/response
import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{type Option}
import gleam/otp/actor
import pipeline/room

/// Hub where rooms are registered
type RoomRegistry {
  RoomRegistry(rooms: Dict(String, room.RoomHandle))
}

pub type RoomRegistryMsg {
  ListRooms(reply_to: Subject(List(response.RoomSummary)))
  GetRoom(reply_to: Subject(Option(room.RoomHandle)), id: String)
  CreateRoom(reply_to: Subject(Result(Nil, Nil)), name: String, max_user: Int)
}

fn handle(
  state: RoomRegistry,
  msg: RoomRegistryMsg,
) -> actor.Next(RoomRegistry, RoomRegistryMsg) {
  let RoomRegistry(rooms:) = state
  case msg {
    ListRooms(reply_to:) -> {
      let summaries =
        dict.values(rooms)
        |> list.map(fn(handle: room.RoomHandle) {
          response.RoomSummary(
            id: handle.id,
            name: handle.name,
            max_size: handle.max_size,
            current_size: handle.current_size,
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
          actor.continue(RoomRegistry(dict.insert(rooms, name, handle)))
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
  let assert Ok(actor) =
    actor.new(RoomRegistry(rooms: dict.new()))
    |> actor.on_message(handle)
    |> actor.start
  actor.data
}
