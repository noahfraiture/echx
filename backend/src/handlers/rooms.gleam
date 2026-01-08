//// Room list and join handling.

import domain/chat
import domain/response
import domain/session
import gleam/list
import gleam/option
import gleam/otp/actor
import handlers/reply
import room
import room_registry

pub fn list_rooms(state: session.Session) -> reply.Reply {
  let rooms = actor.call(state.registry, 1000, room_registry.ListRooms)
  let rooms =
    list.map(rooms, fn(room: response.RoomSummary) {
      response.RoomSummary(..room, joined: list.contains(state.rooms, room.id))
    })
  reply.Response(response.ListRooms(rooms))
}

pub fn join_room(
  state: session.Session,
  room_id: String,
) -> #(session.Session, reply.Reply) {
  use _token, _name <- try_authentication(state)
  use inbox <- try(state, state.inbox, "no inbox available")
  use room_handle <- try(
    state,
    actor.call(state.registry, 1000, fn(reply_to) {
      room_registry.GetRoom(reply_to, room_id)
    }),
    "room not found",
  )

  let join_result = actor.call(room_handle.command, 1000, room.Join(_, inbox))
  case join_result {
    Ok(_) -> {
      let next_state = session.Session(..state, rooms: [room_id, ..state.rooms])
      #(next_state, reply.Response(response.JoinRoom(Ok(Nil))))
    }
    Error(_) -> #(
      state,
      reply.Response(response.JoinRoom(Error("join rejected"))),
    )
  }
}

fn try(
  state: session.Session,
  v: option.Option(val),
  msg: String,
  success: fn(val) -> #(session.Session, reply.Reply),
) -> #(session.Session, reply.Reply) {
  case v {
    option.None -> #(state, reply.Response(response.JoinRoom(Error(msg))))
    option.Some(inbox) -> success(inbox)
  }
}

fn try_authentication(
  state: session.Session,
  success: fn(String, String) -> #(session.Session, reply.Reply),
) -> #(session.Session, reply.Reply) {
  case state.user {
    chat.Unknown -> #(
      state,
      reply.Response(response.JoinRoom(Error("unauthenticated"))),
    )
    chat.User(token:, name:) -> success(token, name)
  }
}
