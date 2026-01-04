import chat
import gleam/bytes_tree
import gleam/erlang/process.{type Subject}
import gleam/http/request.{type Request}
import gleam/http/response.{type Response}
import gleam/option.{type Option, None, Some}
import gleam/result
import mist
import room_registry

pub fn handle(ctx: Context, path: List(String)) -> Response(mist.ResponseData) {
  case path {
    ["room", cmd] -> handle_room(ctx, cmd)
    _ ->
      response.new(404)
      |> response.set_body(mist.Bytes(bytes_tree.new()))
  }
}

fn handle_room(ctx: Context, cmd: String) -> Response(mist.ResponseData) {
  case ctx.registry {
    None -> todo
    // internal
    Some(registry) -> {
      case cmd {
        "join" -> {
          todo
        }
        _ ->
          response.new(404)
          |> response.set_body(mist.Bytes(bytes_tree.new()))
      }
    }
  }
}

pub opaque type Context {
  Context(
    registry: Option(Subject(room_registry.RoomRegistryMsg)),
    user: Option(chat.User),
  )
}

pub fn new_context(
  registry: Subject(room_registry.RoomRegistryMsg),
) -> Context {
  Context(Some(registry), None)
}

pub fn authenticate(
  ctx: Context,
  req: Request(mist.Connection),
  callback: fn(Context) -> Response(mist.ResponseData),
) -> Response(mist.ResponseData) {
  case extract_user(req) {
    Error(_) -> {
      response.new(401)
      |> response.set_body(mist.Bytes(bytes_tree.new()))
    }
    Ok(user) -> callback(Context(..ctx, user: Some(user)))
  }
}

fn extract_user(req: Request(mist.Connection)) -> Result(chat.User, Nil) {
  use token <- result.try(request.get_header(req, "token"))
  use name <- result.try(request.get_header(req, "name"))
  Ok(chat.User(token, name))
}
