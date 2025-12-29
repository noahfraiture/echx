import chat
import client
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/otp/actor
import gleam/time/timestamp
import mist
import pipeline
import transport/incoming
import transport/outgoing

pub fn handler(
  entry: Subject(pipeline.Message),
) -> fn(
  client.Client,
  mist.WebsocketMessage(incoming.IncomingMessage),
  mist.WebsocketConnection,
) ->
  mist.Next(client.Client, a) {
  fn(state, message, conn) {
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
  entry: Subject(pipeline.Message),
  state: client.Client,
  payload: String,
  conn: mist.WebsocketConnection,
) -> mist.Next(client.Client, a) {
  case incoming.decode_client_messages(payload) {
    Ok(msgs) -> mist.continue(handle_client_messages(entry, state, msgs, conn))
    Error(_) -> mist.continue(state)
  }
}

// TODO : handle error
//  maybe fail fast and stop connection on error ?
fn handle_client_messages(
  entry: Subject(pipeline.Message),
  state: client.Client,
  msgs: List(incoming.IncomingMessage),
  conn: mist.WebsocketConnection,
) -> client.Client {
  use state, msg <- list.fold(msgs, state)
  case msg {
    incoming.Chat(content) -> {
      case content {
        "ping" -> {
          let assert Ok(_) = mist.send_text_frame(conn, "pong")
          state
        }
        // Debug
        // will be removed in future
        "profile" -> {
          let _ = case state.user {
            chat.Unknown ->
              mist.send_text_frame(
                conn,
                outgoing.encode_server_message(outgoing.Error("user not found")),
              )
            chat.User(token:, name:) ->
              mist.send_text_frame(conn, token <> name)
          }
          state
        }
        _ -> {
          actor.send(
            entry,
            pipeline.Chat(chat.Chat(
              content:,
              user: state.user,
              timestamp: timestamp.system_time(),
            )),
          )
          state
        }
      }
      state
    }
    incoming.Connect(token:, name:) -> {
      client.Client(..state, user: chat.User(token:, name:))
    }
  }
}
