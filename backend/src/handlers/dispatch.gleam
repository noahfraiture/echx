//// Dispatches requests to feature handlers.

import domain/chat as domain_chat
import domain/request
import domain/response
import domain/session
import gleam/erlang/process.{type Subject}
import gleam/list
import handlers/chat
import handlers/rooms
import handlers/session as session_handler
import pipeline/envelope

pub fn handle_requests(
  entry: Subject(envelope.Envelope),
  state: session.Session,
  requests: List(request.Request),
) -> #(session.Session, List(response.Response)) {
  list.fold(requests, #(state, []), fn(acc, req) {
    let #(current_state, replies) = acc
    let #(next_state, reply) = handle_request(entry, current_state, req)
    #(next_state, list.append(replies, [reply]))
  })
}

pub fn handle_request(
  pipeline: Subject(envelope.Envelope),
  state: session.Session,
  req: request.Request,
) -> #(session.Session, response.Response) {
  echo req as "request"
  use <- try_auth(state, req)
  case req {
    request.Chat(content, room_id, message_id) ->
      chat.handle(pipeline, state, content, room_id, message_id)
    request.Connect(token:, name:) -> #(
      session_handler.connect(state, token, name),
      response.Success,
    )
    request.ListRooms -> #(state, rooms.list_rooms(state))
    request.JoinRoom(room_id) -> {
      let #(next_state, reply_msg) = rooms.join_room(state, room_id)
      #(next_state, reply_msg)
    }
    request.CreateRoom(name, max_size) -> {
      let #(next_state, reply_msg) = rooms.create_room(state, name, max_size)
      #(next_state, reply_msg)
    }
  }
}

fn try_auth(
  state: session.Session,
  req: request.Request,
  connected: fn() -> #(session.Session, response.Response),
) -> #(session.Session, response.Response) {
  case state.user {
    domain_chat.User(_, _) -> connected()
    domain_chat.Unknown -> {
      case req {
        request.Connect(token:, name:) -> #(
          session_handler.connect(state, token, name),
          response.Success,
        )
        _ -> #(state, response.Unauthorized("unauthenticated"))
      }
    }
  }
}
