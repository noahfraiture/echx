import domain/chat
import domain/response
import gleam/dynamic/decode
import gleam/json
import gleam/option.{None}
import gleam/time/timestamp
import transport/outgoing

fn sample_chat(content: String) -> chat.Chat {
  chat.Chat(
    content,
    chat.User("token-1", "Neo"),
    timestamp.from_unix_seconds(1),
    "msg-" <> content,
  )
}

pub fn encode_server_room_event_test() {
  let decoder =
    decode.field("type", decode.string, fn(msg_type) {
      decode.at(["chat", "content"], decode.string)
      |> decode.then(fn(content) {
        decode.at(["chat", "user", "name"], decode.string)
        |> decode.then(fn(name) {
          decode.at(["chat", "message_id"], decode.string)
          |> decode.then(fn(message_id) {
            decode.success(#(msg_type, #(content, #(name, message_id))))
          })
        })
      })
    })

  let encoded =
    outgoing.encode_server_message(response.RoomEvent(sample_chat("hey")))

  let assert Ok(#("room_event", #("hey", #("Neo", "msg-hey")))) =
    json.parse(encoded, decoder)
}

pub fn encode_server_room_event_unknown_user_test() {
  let decoder =
    decode.at(["chat", "user", "name"], decode.optional(decode.string))
  let encoded =
    outgoing.encode_server_message(
      response.RoomEvent(chat.Chat(
        "hey",
        chat.Unknown,
        timestamp.from_unix_seconds(2),
        "msg-hey",
      )),
    )

  let assert Ok(None) = json.parse(encoded, decoder)
}

pub fn encode_server_room_event_timestamp_fields_test() {
  let decoder =
    decode.at(["chat", "timestamp", "seconds"], decode.int)
    |> decode.then(fn(seconds) {
      decode.at(["chat", "timestamp", "nanoseconds"], decode.int)
      |> decode.then(fn(nanoseconds) { decode.success(#(seconds, nanoseconds)) })
    })

  let encoded =
    outgoing.encode_server_message(
      response.RoomEvent(chat.Chat(
        "time",
        chat.User("token-1", "Neo"),
        timestamp.from_unix_seconds(42),
        "msg-time",
      )),
    )

  let assert Ok(#(42, 0)) = json.parse(encoded, decoder)
}

pub fn encode_server_room_event_includes_user_name_only_test() {
  let decoder =
    decode.at(["chat", "user"], decode.dynamic)
    |> decode.then(fn(user_json) {
      let name = decode.run(user_json, decode.at(["name"], decode.string))
      let token = decode.run(user_json, decode.at(["token"], decode.string))
      decode.success(#(name, token))
    })

  let encoded =
    outgoing.encode_server_message(
      response.RoomEvent(chat.Chat(
        "hello",
        chat.User("secret-token", "Neo"),
        timestamp.from_unix_seconds(1),
        "msg-hello",
      )),
    )

  let assert Ok(#(Ok("Neo"), Error(_))) = json.parse(encoded, decoder)
}

pub fn encode_server_error_test() {
  let decoder =
    decode.field("type", decode.string, fn(msg_type) {
      decode.field("message", decode.string, fn(message) {
        decode.success(#(msg_type, message))
      })
    })

  let encoded = outgoing.encode_server_message(response.ErrorMsg("boom"))

  let assert Ok(#("error", "boom")) = json.parse(encoded, decoder)
}

pub fn encode_server_list_rooms_test() {
  let decoder =
    decode.field("type", decode.string, fn(msg_type) {
      decode.field(
        "rooms",
        decode.list(
          decode.field("id", decode.string, fn(id) {
            decode.field("name", decode.string, fn(name) {
              decode.field("joined", decode.bool, fn(joined) {
                decode.success(#(id, #(name, joined)))
              })
            })
          }),
        ),
        fn(rooms) { decode.success(#(msg_type, rooms)) },
      )
    })

  let encoded =
    outgoing.encode_server_message(
      response.ListRooms([
        response.RoomSummary(
          id: "lobby",
          name: "Lobby",
          max_size: 2,
          current_size: 0,
        ),
        response.RoomSummary(
          id: "games",
          name: "Games",
          max_size: 2,
          current_size: 0,
        ),
      ]),
    )

  let assert Ok(#("list_rooms", rooms)) = json.parse(encoded, decoder)
  assert rooms
    == [
      #("lobby", #("Lobby", True)),
      #("games", #("Games", False)),
    ]
}

pub fn encode_server_join_room_ok_test() {
  let decoder =
    decode.field("type", decode.string, fn(msg_type) {
      decode.field("status", decode.string, fn(status) {
        decode.field("reason", decode.optional(decode.string), fn(reason) {
          decode.success(#(msg_type, #(status, reason)))
        })
      })
    })

  let encoded = outgoing.encode_server_message(response.JoinRoom(Ok(Nil)))

  let assert Ok(#("join_room", #("ok", None))) = json.parse(encoded, decoder)
}

pub fn encode_server_join_room_error_test() {
  let decoder =
    decode.field("type", decode.string, fn(msg_type) {
      decode.field("status", decode.string, fn(status) {
        decode.field("reason", decode.string, fn(reason) {
          decode.success(#(msg_type, #(status, reason)))
        })
      })
    })

  let encoded =
    outgoing.encode_server_message(response.JoinRoom(Error("room not found")))

  let assert Ok(#("join_room", #("error", "room not found"))) =
    json.parse(encoded, decoder)
}
