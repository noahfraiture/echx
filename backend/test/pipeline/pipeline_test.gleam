import domain/chat
import gleam/erlang/process
import gleam/time/timestamp
import pipeline/envelope
import pipeline/stage_processing
import pipeline/stage_validation
import room_registry

fn sample_chat(content: String) -> chat.Chat {
  chat.Chat(
    content,
    chat.User(name: "tester", token: "123"),
    timestamp.from_unix_seconds(0),
    "msg-" <> content,
  )
}

fn setup_registry(
  room_id: String,
) -> process.Subject(room_registry.RoomRegistryMsg) {
  let registry = room_registry.new()
  let assert Ok(_) = room_registry.new_room(registry, room_id)
  registry
}

pub fn processing_subscribes_to_upstream_on_start_test() {
  let upstream = process.new_subject()
  let registry = setup_registry("lobby")
  let assert Ok(_processing) = stage_processing.start([upstream], registry)

  let assert Ok(envelope.Control(envelope.Subscribe(from: _))) =
    process.receive(upstream, within: 50)
}

pub fn processing_subscribes_to_multiple_upstreams_on_start_test() {
  let upstream_a = process.new_subject()
  let upstream_b = process.new_subject()
  let registry = setup_registry("lobby")
  let assert Ok(_processing) =
    stage_processing.start([upstream_a, upstream_b], registry)

  let assert Ok(envelope.Control(envelope.Subscribe(from: _))) =
    process.receive(upstream_a, within: 50)
  let assert Ok(envelope.Control(envelope.Subscribe(from: _))) =
    process.receive(upstream_b, within: 50)
}

pub fn multiple_downstreams_subscribe_to_single_upstream_test() {
  let upstream = process.new_subject()
  let registry = setup_registry("lobby")
  let assert Ok(_first) = stage_processing.start([upstream], registry)
  let assert Ok(_second) = stage_processing.start([upstream], registry)

  let assert Ok(envelope.Control(envelope.Subscribe(from: _))) =
    process.receive(upstream, within: 50)
  let assert Ok(envelope.Control(envelope.Subscribe(from: _))) =
    process.receive(upstream, within: 50)
}

pub fn two_stage_chain_forwards_to_downstream_listener_test() {
  let room_id = "lobby"
  let registry = setup_registry(room_id)
  let assert Ok(validation) = stage_validation.start([])
  let assert Ok(processing) = stage_processing.start([validation], registry)
  let listener = process.new_subject()

  process.send(processing, envelope.Control(envelope.Subscribe(listener)))
  process.send(
    validation,
    envelope.Event(envelope.Chat(sample_chat("two-stage"), room_id)),
  )

  let assert Ok(envelope.Event(envelope.Chat(
    chat.Chat(content: content, message_id: message_id, ..),
    "lobby",
  ))) = process.receive(listener, within: 50)
  assert content == "two-stage"
  assert message_id == "msg-two-stage"
}

pub fn multi_stage_chain_forwards_to_terminal_listener_test() {
  let room_id = "lobby"
  let registry = setup_registry(room_id)
  let assert Ok(validation) = stage_validation.start([])
  let assert Ok(first) = stage_processing.start([validation], registry)
  let assert Ok(second) = stage_processing.start([first], registry)
  let listener = process.new_subject()

  process.send(second, envelope.Control(envelope.Subscribe(listener)))
  process.send(
    validation,
    envelope.Event(envelope.Chat(sample_chat("multi-stage"), room_id)),
  )

  let assert Ok(envelope.Event(envelope.Chat(
    chat.Chat(content: content, message_id: message_id, ..),
    "lobby",
  ))) = process.receive(listener, within: 50)
  assert content == "multi-stage"
  assert message_id == "msg-multi-stage"
}
