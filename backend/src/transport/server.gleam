import domain/chat
import domain/session
import gleam/bytes_tree
import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/io
import gleam/option.{None, Some}
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
            on_init: fn(conn) {
              #(
                session.Session(
                  registry:,
                  user: chat.Unknown,
                  inbox: Some(websocket.start_inbox(conn)),
                  rooms: [],
                ),
                None,
              )
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

        ["api", ..path] ->
          rest.authenticate(rest.new_context(registry), req, fn(ctx) {
            rest.handle(ctx, req, path, entry)
          })

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
