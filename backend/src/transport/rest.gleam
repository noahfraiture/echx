import domain/chat
import domain/session
import gleam/bit_array
import gleam/bytes_tree
import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{None, Some}
import gleam/result
import domain/response as domain_response
import handlers/dispatch
import handlers/reply
import mist
import pipeline
import transport/incoming
import transport/outgoing
import room_registry

pub fn handle(
  ctx: session.Context,
  req: Request(mist.Connection),
  path: List(String),
  entry: Subject(pipeline.Message),
) -> Response(mist.ResponseData) {
  case path {
    _ -> handle_json(ctx, req, entry)
  }
}

fn handle_json(
  ctx: session.Context,
  req: Request(mist.Connection),
  entry: Subject(pipeline.Message),
) -> Response(mist.ResponseData) {
  case ctx.registry, ctx.user {
    Some(registry), Some(user) -> {
      case mist.read_body(req, 1_000_000) {
        Error(_) -> bad_request("invalid body")
        Ok(req) -> {
          case bit_array.to_string(req.body) {
            Error(_) -> bad_request("invalid body")
            Ok(payload) ->
              handle_payload(registry, user, entry, payload)
          }
        }
      }
    }
    _, _ ->
      response.new(401)
      |> response.set_body(mist.Bytes(bytes_tree.new()))
  }
}

fn handle_payload(
  registry: Subject(room_registry.RoomRegistryMsg),
  user: chat.User,
  entry: Subject(pipeline.Message),
  payload: String,
) -> Response(mist.ResponseData) {
  case incoming.decode_client_messages(payload) {
    Error(_) -> bad_request("invalid json")
    Ok(msgs) ->
      case msgs {
        [msg] -> {
          let state =
            session.Session(
              registry: registry,
              user: user,
              inbox: None,
              rooms: [],
            )
          let #(_, replies) =
            dispatch.handle_requests(entry, state, [msg])
          reply_to_response(replies)
        }
        _ -> bad_request("only single-message requests are supported")
      }
  }
}

fn bad_request(reason: String) -> Response(mist.ResponseData) {
  let payload = outgoing.encode_server_message(domain_response.ErrorMsg(reason))
  response.new(400)
  |> response.set_body(mist.Bytes(bytes_tree.from_string(payload)))
}

fn reply_to_response(replies: List(reply.Reply)) -> Response(mist.ResponseData) {
  case replies {
    [] -> response.new(204) |> response.set_body(mist.Bytes(bytes_tree.new()))
    [reply.Response(message)] -> {
      let payload = outgoing.encode_server_message(message)
      response.new(200)
      |> response.set_body(mist.Bytes(bytes_tree.from_string(payload)))
    }
    [reply.Text(_)] ->
      bad_request("text responses are not supported over rest")
    _ -> bad_request("only single responses are supported")
  }
}

pub fn new_context(
  registry: Subject(room_registry.RoomRegistryMsg),
) -> session.Context {
  session.Context(Some(registry), None)
}

pub fn authenticate(
  ctx: session.Context,
  req: Request(mist.Connection),
  callback: fn(session.Context) -> Response(mist.ResponseData),
) -> Response(mist.ResponseData) {
  case extract_user(req) {
    Error(_) -> {
      response.new(401)
      |> response.set_body(mist.Bytes(bytes_tree.new()))
    }
    Ok(user) -> callback(session.Context(..ctx, user: Some(user)))
  }
}

fn extract_user(req: Request(mist.Connection)) -> Result(chat.User, Nil) {
  use token <- result.try(request.get_header(req, "token"))
  use name <- result.try(request.get_header(req, "name"))
  Ok(chat.User(token, name))
}
