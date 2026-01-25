//// Room list and join handling.

import domain/chat
import domain/response
import domain/session
import gleam/bool
import gleam/list
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
    Ok(trimmed_name) -> {
      let result =
        room_registry.new_room(state.registry, trimmed_name, max_size)
      case result {
        Ok(_) -> #(state, response.CreateRoom(Ok(Nil)))
        Error(error) -> #(
          state,
          response.CreateRoom(Error(room_registry.error_message(error))),
        )
      }
    }
  }
}

fn validate_room(name: String, max_size: Int) -> Result(String, String) {
  let trimmed = string.trim(name)
  let name_length = string.length(trimmed)
  use <- bool.guard(
    name_length < 3 || name_length > 50,
    Error("name must be between 3 and 50 characters"),
  )
  use <- bool.guard(
    max_size < 3 || max_size > 50,
    Error("max size must be between 3 and 50"),
  )
  use <- bool.guard(
    !has_only_name_chars(trimmed),
    Error("name may only include letters, numbers, and spaces"),
  )
  Ok(trimmed)
}

fn has_only_name_chars(name: String) -> Bool {
  name
  |> string.to_utf_codepoints
  |> list.all(satisfying: fn(codepoint) {
    let value = string.utf_codepoint_to_int(codepoint)
    value >= 48
    && value <= 57
    || value >= 65
    && value <= 90
    || value >= 97
    && value <= 122
    || value == 32
  })
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
