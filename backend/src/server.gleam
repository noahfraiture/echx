import chat
import client
import gleam/bytes_tree
import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
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
            // TODO : on init, create a random token and save in the cache
            on_init: fn(_conn) {
              #(Connection(client.new(registry, chat.User("new user"))), None)
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
    |> mist.port(0)
    |> mist.start
}

type Connection {
  Connection(client: client.Client)
}

fn handler(
  entry: Subject(pipeline.Message),
) -> fn(
  Connection,
  mist.WebsocketMessage(protocol.ClientMessage),
  mist.WebsocketConnection,
) ->
  mist.Next(Connection, a) {
  fn(state, message, conn) {
    case message {
      mist.Text("ping") -> {
        let assert Ok(_) = mist.send_text_frame(conn, "pong")
        mist.continue(state)
      }
      mist.Text(payload) -> handle_text_message(entry, state, payload, conn)
      mist.Closed | mist.Shutdown -> mist.stop()
      mist.Custom(msg) -> handle_client_message(entry, state, msg, conn)
      _ -> mist.continue(state)
    }
  }
}

fn handle_text_message(
  entry: Subject(pipeline.Message),
  state: Connection,
  payload: String,
  conn: mist.WebsocketConnection,
) -> mist.Next(Connection, a) {
  case protocol.decode_client_message(payload) {
    Ok(msg) -> handle_client_message(entry, state, msg, conn)
    Error(_) -> mist.continue(state)
  }
}

fn handle_client_message(
  entry: Subject(pipeline.Message),
  state: Connection,
  msg: protocol.ClientMessage,
  conn: mist.WebsocketConnection,
) {
  // TODO : handle error
  let _ = case msg {
    protocol.Chat(content) -> {
      actor.send(
        entry,
        pipeline.Chat(chat.Chat(
          content:,
          user: state.client.user,
          timestamp: timestamp.system_time(),
        )),
      )
      let assert Ok(_) = mist.send_text_frame(conn, "hello")
    }
  }
  mist.continue(state)
}
