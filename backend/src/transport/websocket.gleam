//// WebSocket adapter for JSON frames.

import domain/response
import domain/session
import gleam/erlang/process
import gleam/list
import handlers/dispatch
import mist
import pipeline/envelope
import transport/incoming
import transport/outgoing

pub fn inbox() -> #(
  process.Subject(response.Response),
  process.Selector(response.Response),
) {
  let inbox = process.new_subject()
  let selector = process.new_selector() |> process.select(inbox)
  #(inbox, selector)
}

// handler return a function that handles the incoming message from the
// internal backend to send to a client.
pub fn handler(
  entry: process.Subject(envelope.Envelope),
) -> fn(
  session.Session,
  mist.WebsocketMessage(response.Response),
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
      mist.Custom(message) -> {
        send_response(conn, message)
        mist.continue(state)
      }
      mist.Closed | mist.Shutdown -> mist.stop()
      _ -> mist.continue(state)
    }
  }
}

// Handle text message as json.
// Every message has will receive a response. Regular chat message can ignore
// the response, but request such as list_rooms or join_room expect a response.
fn handle_text_message(
  entry: process.Subject(envelope.Envelope),
  state: session.Session,
  payload: String,
  conn: mist.WebsocketConnection,
) -> mist.Next(session.Session, a) {
  let #(next_state, replies) = handle_payload(entry, state, payload)
  list.each(replies, fn(response) { send_response(conn, response) })
  mist.continue(next_state)
}

pub fn handle_payload(
  entry: process.Subject(envelope.Envelope),
  state: session.Session,
  payload: String,
) -> #(session.Session, List(response.Response)) {
  case incoming.decode_client_messages(payload) {
    Ok(requests) -> dispatch.handle_requests(entry, state, requests)
    Error(_) -> #(state, [])
  }
}

fn send_response(
  conn: mist.WebsocketConnection,
  message: response.Response,
) -> Nil {
  let _ = mist.send_text_frame(conn, outgoing.encode_server_message(message))
  Nil
}
