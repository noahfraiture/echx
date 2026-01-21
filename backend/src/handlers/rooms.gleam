//// Room list and join handling.

import domain/response
import domain/session
import gleam/option
import gleam/otp/actor
import pipeline/room
import room_registry

pub fn list_rooms(state: session.Session) -> response.Response {
  let rooms = actor.call(state.registry, 1000, room_registry.ListRooms)
  response.ListRooms(rooms)
}

pub fn join_room(
  state: session.Session,
  room_id: String,
) -> #(session.Session, response.Response) {
  use room_handle <- try(
    state,
    actor.call(state.registry, 1000, fn(reply_to) {
      room_registry.GetRoom(reply_to, room_id)
    }),
    "room not found",
  )

  let join_result =
    actor.call(room_handle.command, 1000, room.Join(_, state.inbox))
  case join_result {
    response.Success -> {
      let next_state = session.Session(..state, rooms: [room_id, ..state.rooms])
      #(next_state, response.JoinRoom(Ok(Nil)))
    }
    other -> #(state, other)
  }
}

fn try(
  state: session.Session,
  v: option.Option(val),
  msg: String,
  success: fn(val) -> #(session.Session, response.Response),
) -> #(session.Session, response.Response) {
  case v {
    option.None -> #(state, response.JoinRoom(Error(msg)))
    option.Some(inbox) -> success(inbox)
  }
}
