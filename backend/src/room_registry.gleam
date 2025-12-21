import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor
import room

/// Hub where rooms are registered
type RoomRegistry {
  RoomRegistry(rooms: Dict(String, room.RoomHandle))
}

type ListRoomsResult =
  Result(List(room.RoomSummary), Nil)

type GetRoomResult =
  Result(room.RoomHandle, Nil)

type AddRoomResult =
  Result(Nil, Nil)

pub type RoomRegistryMsg {
  ListRooms(reply_to: Subject(ListRoomsResult))
  GetRoom(reply_to: Subject(GetRoomResult), id: room.RoomID)
  AddRoom(reply_to: Subject(AddRoomResult), room: room.RoomHandle)
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
          room.RoomSummary(id: handle.id, name: handle.name)
        })
      actor.send(reply_to, Ok(summaries))
      actor.continue(state)
    }
    GetRoom(reply_to:, id:) -> {
      actor.send(reply_to, dict.get(rooms, id))
      actor.continue(state)
    }
    AddRoom(reply_to:, room:) -> {
      case dict.has_key(rooms, room.id) {
        True -> {
          actor.send(reply_to, Error(Nil))
          actor.continue(state)
        }
        False -> {
          actor.send(reply_to, Ok(Nil))
          actor.continue(RoomRegistry(rooms: dict.insert(rooms, room.id, room)))
        }
      }
    }
  }
}

pub fn new() -> Subject(RoomRegistryMsg) {
  let assert Ok(actor) =
    actor.new(RoomRegistry(rooms: dict.new()))
    |> actor.on_message(handle)
    |> actor.start
  actor.data
}
