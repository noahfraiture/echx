//// WebSocket adapter for JSON frames.

import domain/request
import domain/response
import domain/session
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor
import handlers/dispatch
import handlers/reply
import mist
import pipeline/envelope
import transport/incoming
import transport/outgoing

pub fn start_inbox(conn: mist.WebsocketConnection) -> Subject(response.Response) {
  let assert Ok(actor.Started(_, inbox)) =
    actor.new(conn)
    |> actor.on_message(
      fn(conn: mist.WebsocketConnection, msg: response.Response) {
        let _ = mist.send_text_frame(conn, outgoing.encode_server_message(msg))
        actor.continue(conn)
      },
    )
    |> actor.start

  inbox
}

pub fn handler(
  entry: Subject(envelope.Envelope),
) -> fn(
  session.Session,
  mist.WebsocketMessage(request.Request),
  mist.WebsocketConnection,
) ->
  mist.Next(session.Session, a) {
  fn(state, message, conn) {
    echo message as "message"
    case message {
      mist.Text("ping") -> {
        let assert Ok(_) = mist.send_text_frame(conn, "pong")
        mist.continue(state)
      }
      mist.Text(payload) -> handle_text_message(entry, state, payload, conn)
      mist.Closed | mist.Shutdown -> mist.stop()
      _ -> mist.continue(state)
    }
  }
}

fn handle_text_message(
  entry: Subject(envelope.Envelope),
  state: session.Session,
  payload: String,
  conn: mist.WebsocketConnection,
) -> mist.Next(session.Session, a) {
  let #(next_state, replies) = handle_payload(entry, state, payload)
  list.each(replies, fn(reply_msg) { send_reply(conn, reply_msg) })
  mist.continue(next_state)
}

pub fn handle_payload(
  entry: Subject(envelope.Envelope),
  state: session.Session,
  payload: String,
) -> #(session.Session, List(reply.Reply)) {
  case incoming.decode_client_messages(payload) {
    Ok(requests) -> dispatch.handle_requests(entry, state, requests)
    Error(_) -> #(state, [])
  }
}

fn send_reply(conn: mist.WebsocketConnection, reply: reply.Reply) -> Nil {
  case reply {
    reply.Text(payload) -> {
      let _ = mist.send_text_frame(conn, payload)
      Nil
    }
    reply.Response(message) -> {
      let _ =
        mist.send_text_frame(conn, outgoing.encode_server_message(message))
      Nil
    }
  }
}
