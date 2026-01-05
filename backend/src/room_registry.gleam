import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{type Option}
import gleam/otp/actor
import room
import transport/outgoing

/// Hub where rooms are registered
type RoomRegistry {
  RoomRegistry(rooms: Dict(String, room.RoomHandle))
}

pub type RoomRegistryMsg {
  ListRooms(reply_to: Subject(List(outgoing.RoomSummary)))
  GetRoom(reply_to: Subject(Option(room.RoomHandle)), id: String)
  CreateRoom(reply_to: Subject(Result(Nil, Nil)), name: String)
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
          outgoing.RoomSummary(id: handle.id, name: handle.name, joined: False)
        })
      actor.send(reply_to, summaries)
      actor.continue(state)
    }
    GetRoom(reply_to:, id:) -> {
      actor.send(reply_to, option.from_result(dict.get(rooms, id)))
      actor.continue(state)
    }
    CreateRoom(reply_to:, name:) -> {
      case dict.has_key(state.rooms, name) {
        False -> {
          case room.start(name) {
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
  }
}

pub fn new_room(
  registry: Subject(RoomRegistryMsg),
  name: String,
) -> Result(Nil, Nil) {
  actor.call(registry, 1000, CreateRoom(_, name))
}

pub fn new() -> Subject(RoomRegistryMsg) {
  let assert Ok(actor) =
    actor.new(RoomRegistry(rooms: dict.new()))
    |> actor.on_message(handle)
    |> actor.start
  actor.data
}
