//// Dispatches requests to feature handlers.

import domain/request
import domain/session
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option.{type Option, None, Some}
import handlers/chat
import handlers/reply
import handlers/rooms
import handlers/session as session_handler
import pipeline/envelope

pub fn handle_requests(
  entry: Subject(envelope.Envelope),
  state: session.Session,
  requests: List(request.Request),
) -> #(session.Session, List(reply.Reply)) {
  list.fold(requests, #(state, []), fn(acc, req) {
    let #(current_state, replies) = acc
    let #(next_state, maybe_reply) = handle_request(entry, current_state, req)
    let replies = case maybe_reply {
      None -> replies
      Some(reply_msg) -> list.append(replies, [reply_msg])
    }
    #(next_state, replies)
  })
}

pub fn handle_request(
  entry: Subject(envelope.Envelope),
  state: session.Session,
  req: request.Request,
) -> #(session.Session, Option(reply.Reply)) {
  echo req as "request"
  case req {
    request.Chat(content, room_id) ->
      chat.handle(entry, state, content, room_id)
    request.Connect(token:, name:) -> #(
      session_handler.connect(state, token, name),
      None,
    )
    request.ListRooms -> #(state, Some(rooms.list_rooms(state)))
    request.JoinRoom(room_id) -> {
      let #(next_state, reply_msg) = rooms.join_room(state, room_id)
      #(next_state, Some(reply_msg))
    }
  }
}
