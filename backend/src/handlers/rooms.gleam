//// Room list and join handling.

import domain/chat
import domain/response
import domain/session
import gleam/option
import gleam/otp/actor
import gleam/string
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

  let assert chat.User(token:, name: _) = state.user
  let join_result =
    actor.call(room_handle.command, 1000, room.Join(_, token, state.inbox))
  case join_result {
    response.Success -> {
      let next_state = session.Session(..state, rooms: [room_id, ..state.rooms])
      #(next_state, response.JoinRoom(Ok(Nil)))
    }
    other -> #(state, other)
  }
}

pub fn create_room(
  state: session.Session,
  name: String,
  max_size: Int,
) -> #(session.Session, response.Response) {
  case validate_room(name, max_size) {
    Error(message) -> #(state, response.CreateRoom(Error(message)))
    Ok(normalized_name) -> {
      let result =
        room_registry.new_room(state.registry, normalized_name, max_size)
      case result {
        Ok(_) -> #(state, response.CreateRoom(Ok(Nil)))
        Error(_) -> #(
          state,
          response.CreateRoom(Error("unable to create room")),
        )
      }
    }
  }
}

fn validate_room(name: String, max_size: Int) -> Result(String, String) {
  let trimmed = string.trim(name)
  let name_length = string.length(trimmed)
  case name_length < 3 || name_length > 50 {
    True -> Error("name must be between 3 and 50 characters")
    False ->
      case max_size < 3 || max_size > 50 {
        True -> Error("max size must be between 3 and 50")
        False -> Ok(trimmed)
      }
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
