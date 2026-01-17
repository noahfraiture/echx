//// Dispatches requests to feature handlers.

import domain/request
import domain/response
import domain/session
import gleam/erlang/process.{type Subject}
import gleam/list
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
    let #(next_state, reply) = handle_request(entry, current_state, req)
    #(next_state, list.append(replies, [reply]))
  })
}

pub fn handle_request(
  entry: Subject(envelope.Envelope),
  state: session.Session,
  req: request.Request,
) -> #(session.Session, reply.Reply) {
  echo req as "request"
  case req {
    request.Chat(content, room_id) ->
      chat.handle(entry, state, content, room_id)
    request.Connect(token:, name:) -> #(
      session_handler.connect(state, token, name),
      reply.Response(response.Success),
    )
    request.ListRooms -> #(state, rooms.list_rooms(state))
    request.JoinRoom(room_id) -> {
      let #(next_state, reply_msg) = rooms.join_room(state, room_id)
      #(next_state, reply_msg)
    }
  }
}
