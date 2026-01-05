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
  case state.user {
    chat.Unknown -> #(
      state,
      reply.Response(response.JoinRoom(Error("unauthenticated"))),
    )
    chat.User(_, _) ->
      case state.inbox {
        option.None -> #(
          state,
          reply.Response(response.JoinRoom(Error("no inbox available"))),
        )
        option.Some(inbox) -> {
          let existing =
            actor.call(state.registry, 1000, fn(reply_to) {
              room_registry.GetRoom(reply_to, room_id)
            })

          case existing {
            option.None -> #(
              state,
              reply.Response(response.JoinRoom(Error("room not found"))),
            )
            option.Some(room_handle) -> {
              let join_result =
                actor.call(room_handle.command, 1000, room.Join(_, inbox))
              case join_result {
                Ok(_) -> {
                  let next_state =
                    session.Session(..state, rooms: [room_id, ..state.rooms])
                  #(next_state, reply.Response(response.JoinRoom(Ok(Nil))))
                }
                Error(_) -> #(
                  state,
                  reply.Response(response.JoinRoom(Error("join rejected"))),
                )
              }
            }
          }
        }
      }
  }
}
