import domain/chat
import gleam/erlang/process
import gleam/time/timestamp
import pipeline/envelope
import pipeline/processing
import pipeline/validation

fn sample_chat(content: String) -> chat.Chat {
  chat.Chat(
    content,
    chat.User(name: "tester", token: "123"),
    timestamp.from_unix_seconds(0),
  )
}

pub fn processing_subscribes_to_upstream_on_start_test() {
  let upstream = process.new_subject()
  let assert Ok(_processing) = processing.start([upstream])

  let assert Ok(envelope.Control(envelope.Subscribe(from: _))) =
    process.receive(upstream, within: 50)
}

pub fn processing_subscribes_to_multiple_upstreams_on_start_test() {
  let upstream_a = process.new_subject()
  let upstream_b = process.new_subject()
  let assert Ok(_processing) = processing.start([upstream_a, upstream_b])

  let assert Ok(envelope.Control(envelope.Subscribe(from: _))) =
    process.receive(upstream_a, within: 50)
  let assert Ok(envelope.Control(envelope.Subscribe(from: _))) =
    process.receive(upstream_b, within: 50)
}

pub fn multiple_downstreams_subscribe_to_single_upstream_test() {
  let upstream = process.new_subject()
  let assert Ok(_first) = processing.start([upstream])
  let assert Ok(_second) = processing.start([upstream])

  let assert Ok(envelope.Control(envelope.Subscribe(from: _))) =
    process.receive(upstream, within: 50)
  let assert Ok(envelope.Control(envelope.Subscribe(from: _))) =
    process.receive(upstream, within: 50)
}

pub fn two_stage_chain_forwards_to_downstream_listener_test() {
  let assert Ok(validation) = validation.start([])
  let assert Ok(processing) = processing.start([validation])
  let listener = process.new_subject()

  process.send(processing, envelope.Control(envelope.Subscribe(listener)))
  process.send(
    validation,
    envelope.Event(envelope.Chat(sample_chat("two-stage"), "")),
  )

  let assert Ok(envelope.Event(envelope.Chat(
    chat.Chat(content: content, ..),
    "",
  ))) = process.receive(listener, within: 50)
  assert content == "two-stage"
}

pub fn multi_stage_chain_forwards_to_terminal_listener_test() {
  let assert Ok(validation) = validation.start([])
  let assert Ok(first) = processing.start([validation])
  let assert Ok(second) = processing.start([first])
  let listener = process.new_subject()

  process.send(second, envelope.Control(envelope.Subscribe(listener)))
  process.send(
    validation,
    envelope.Event(envelope.Chat(sample_chat("multi-stage"), "")),
  )

  let assert Ok(envelope.Event(envelope.Chat(
    chat.Chat(content: content, ..),
    "",
  ))) = process.receive(listener, within: 50)
  assert content == "multi-stage"
}
