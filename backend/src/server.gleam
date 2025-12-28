import chat
import client
import gleam/bytes_tree
import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/list
import gleam/option.{None}
import gleam/otp/actor
import gleam/string
import gleam/time/timestamp
import logging
import mist.{type ResponseData}
import pipeline
import protocol
import room_registry

pub fn new(
  registry: Subject(room_registry.RoomRegistryMsg),
  entry: Subject(pipeline.Message),
) {
  let assert Ok(_) =
    fn(req: Request(mist.Connection)) -> Response(ResponseData) {
      logging.log(
        logging.Info,
        "Got a request from: " <> string.inspect(mist.get_client_info(req.body)),
      )
      case request.path_segments(req) {
        ["ws"] ->
          mist.websocket(
            request: req,
            on_init: fn(_conn) {
              #(client.Client(registry, chat.Unknown), None)
            },
            on_close: fn(_state) { io.println("goodbye!") },
            handler: handler(entry),
          )
        ["ping"] ->
          response.new(200)
          |> response.set_body(mist.Bytes(bytes_tree.from_string("pong")))

        _ ->
          response.new(404)
          |> response.set_body(mist.Bytes(bytes_tree.new()))
      }
    }
    |> mist.new
    |> mist.bind("localhost")
    |> mist.with_ipv6
    |> mist.port(8080)
    |> mist.start
}

fn handler(
  entry: Subject(pipeline.Message),
) -> fn(
  client.Client,
  mist.WebsocketMessage(protocol.ClientMessage),
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
  case protocol.decode_client_messages(payload) {
    Ok(msgs) -> mist.continue(handle_client_messages(entry, state, msgs, conn))
    Error(_) -> mist.continue(state)
  }
}

// TODO : handle error
//  maybe fail fast and stop connection on error ?
fn handle_client_messages(
  entry: Subject(pipeline.Message),
  state: client.Client,
  msgs: List(protocol.ClientMessage),
  conn: mist.WebsocketConnection,
) -> client.Client {
  use state, msg <- list.fold(msgs, state)
  case msg {
    protocol.Chat(content) -> {
      case content {
        "ping" -> {
          let assert Ok(_) = mist.send_text_frame(conn, "pong")
          state
        }
        "profile" -> {
          let _ = case state.user {
            chat.Unknown ->
              mist.send_text_frame(
                conn,
                protocol.encode_server_message(protocol.Error("user not found")),
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
    protocol.Connect(token:, name:) -> {
      client.Client(..state, user: chat.User(token:, name:))
    }
  }
}
