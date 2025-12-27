import client
import gleam/bytes_tree
import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/option.{None}
import gleam/string
import logging
import mist.{type ResponseData}
import protocol
import room_registry

pub fn new(registry: Subject(room_registry.RoomRegistryMsg)) {
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
            on_init: fn(_conn) { #(Connection(client.new(registry)), None) },
            on_close: fn(_state) { io.println("goodbye!") },
            handler: handle_ws_message,
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
  Connection(client.Client)
}

fn handle_ws_message(state, message, conn) {
  case message {
    mist.Text("ping") -> {
      let assert Ok(_) = mist.send_text_frame(conn, "pong")
      mist.continue(state)
    }
    mist.Text(payload) -> handle_text_message(state, payload, conn)
    mist.Closed | mist.Shutdown -> mist.stop()
    mist.Custom(msg) -> handle_client_message(state, msg, conn)
    _ -> mist.continue(state)
  }
}

fn handle_text_message(state, payload: String, conn) {
  case protocol.decode_client_message(payload) {
    Ok(msg) -> handle_client_message(state, msg, conn)
    Error(_) -> mist.continue(state)
  }
}

fn handle_client_message(
  state: Connection,
  msg: protocol.ClientMessage,
  conn: mist.WebsocketConnection,
) {
  case msg {
    protocol.Chat(_) -> {
      let assert Ok(_) = mist.send_text_frame(conn, "hello")
      mist.continue(state)
    }
  }
}
