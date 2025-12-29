import chat
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
import pipeline
import room_registry
import transport/rest
import transport/websocket

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
            handler: websocket.handler(entry),
          )
        ["ping"] ->
          response.new(200)
          |> response.set_body(mist.Bytes(bytes_tree.from_string("pong")))

        ["api", "public", ..] -> {
          todo
        }

        ["api", ..path] -> {
          use ctx <- rest.authenticate(rest.new_context(registry), req)
          rest.handle(ctx, path)
        }

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
