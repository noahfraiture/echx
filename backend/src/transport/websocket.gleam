import chat
import client
import gleam/erlang/process.{type Subject}
import gleam/list
import gleam/option
import gleam/otp/actor
import gleam/set
import gleam/time/timestamp
import mist
import pipeline
import room
import room_registry
import transport/incoming
import transport/outgoing

pub fn start_inbox(
  conn: mist.WebsocketConnection,
) -> Subject(outgoing.OutgoingMessage) {
  let assert Ok(actor.Started(_, inbox)) =
    actor.new(conn)
    |> actor.on_message(
      fn(conn: mist.WebsocketConnection, msg: outgoing.OutgoingMessage) {
        let _ = mist.send_text_frame(conn, outgoing.encode_server_message(msg))
        actor.continue(conn)
      },
    )
    |> actor.start

  inbox
}

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
        // Debug
        // will be removed in future
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
                outgoing.encode_server_message(outgoing.ErrorMsg(
                  "user not found",
                )),
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
    incoming.ListRooms -> {
      let rooms = actor.call(state.registry, 1000, room_registry.ListRooms)
      let rooms =
        list.map(rooms, fn(room: outgoing.RoomSummary) {
          outgoing.RoomSummary(
            ..room,
            joined: list.contains(state.rooms, room.id),
          )
        })
      let _ =
        mist.send_text_frame(
          conn,
          outgoing.encode_server_message(outgoing.ListRooms(rooms)),
        )
      state
    }
    incoming.JoinRoom(room_id) -> {
      let result = join_room(state, room_id)
      let _ =
        mist.send_text_frame(
          conn,
          outgoing.encode_server_message(outgoing.JoinRoom(result)),
        )
      case result {
        Error(_) -> state
        Ok(_) -> client.Client(..state, rooms: [room_id, ..state.rooms])
      }
    }
  }
}

fn join_room(state: client.Client, room_id: String) -> Result(Nil, String) {
  case state.user {
    chat.Unknown -> Error("unauthenticated")
    chat.User(_, _) -> {
      let existing =
        actor.call(state.registry, 1000, fn(reply_to) {
          room_registry.GetRoom(reply_to, room_id)
        })

      case existing {
        option.None -> Error("room not found")
        option.Some(room_handle) -> {
          let join_result =
            actor.call(room_handle.command, 1000, room.Join(_, state.inbox))
          case join_result {
            Ok(_) -> Ok(Nil)
            Error(_) -> Error("join rejected")
          }
        }
      }
    }
  }
}
