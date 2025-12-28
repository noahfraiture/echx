import chat
import gleam/erlang/process
import gleam/time/timestamp
import pipeline

fn sample_chat(content: String) -> chat.Chat {
  chat.Chat(
    content,
    chat.User(name: "tester", token: "123"),
    timestamp.from_unix_seconds(0),
  )
}

pub fn processing_subscribes_to_upstream_on_start_test() {
  let upstream = process.new_subject()
  let assert Ok(_processing) = pipeline.start_processing([upstream])

  let assert Ok(pipeline.Subscribe(from: _)) =
    process.receive(upstream, within: 50)
}

pub fn processing_subscribes_to_multiple_upstreams_on_start_test() {
  let upstream_a = process.new_subject()
  let upstream_b = process.new_subject()
  let assert Ok(_processing) =
    pipeline.start_processing([upstream_a, upstream_b])

  let assert Ok(pipeline.Subscribe(from: _)) =
    process.receive(upstream_a, within: 50)
  let assert Ok(pipeline.Subscribe(from: _)) =
    process.receive(upstream_b, within: 50)
}

pub fn multiple_downstreams_subscribe_to_single_upstream_test() {
  let upstream = process.new_subject()
  let assert Ok(_first) = pipeline.start_processing([upstream])
  let assert Ok(_second) = pipeline.start_processing([upstream])

  let assert Ok(pipeline.Subscribe(from: _)) =
    process.receive(upstream, within: 50)
  let assert Ok(pipeline.Subscribe(from: _)) =
    process.receive(upstream, within: 50)
}

pub fn two_stage_chain_forwards_to_downstream_listener_test() {
  let assert Ok(validation) = pipeline.start_validation([])
  let assert Ok(processing) = pipeline.start_processing([validation])
  let listener = process.new_subject()

  process.send(processing, pipeline.Subscribe(listener))
  process.send(validation, pipeline.Chat(sample_chat("two-stage")))

  let assert Ok(pipeline.Chat(chat.Chat(content: content, ..))) =
    process.receive(listener, within: 50)
  assert content == "two-stage"
}

pub fn multi_stage_chain_forwards_to_terminal_listener_test() {
  let assert Ok(validation) = pipeline.start_validation([])
  let assert Ok(first) = pipeline.start_processing([validation])
  let assert Ok(second) = pipeline.start_processing([first])
  let listener = process.new_subject()

  process.send(second, pipeline.Subscribe(listener))
  process.send(validation, pipeline.Chat(sample_chat("multi-stage")))

  let assert Ok(pipeline.Chat(chat.Chat(content: content, ..))) =
    process.receive(listener, within: 50)
  assert content == "multi-stage"
}
