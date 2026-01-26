//// WebSocket server wiring.

import domain/chat
import domain/session
import gleam/bytes_tree
import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{Some}
import gleam/string
import logging
import mist.{type ResponseData}
import pipeline/envelope
import room_registry
import transport/websocket

pub fn new(
  registry: Subject(room_registry.RoomRegistryMsg),
  entry: Subject(envelope.Envelope),
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
              let #(inbox, selector) = websocket.inbox()
              #(
                session.Session(
                  registry:,
                  user: chat.Unknown,
                  inbox: inbox,
                  rooms: [],
                ),
                Some(selector),
              )
            },
            on_close: fn(_state) { Nil },
            handler: websocket.handler(entry),
          )
        _ ->
          response.new(404)
          |> response.set_body(mist.Bytes(bytes_tree.new()))
      }
    }
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.with_ipv6
    |> mist.port(8080)
    |> mist.start
}
