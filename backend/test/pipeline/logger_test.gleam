import gleam/erlang/process
import pipeline/envelope
import pipeline/stage_logger

pub fn logger_subscribes_to_upstream_on_start_test() {
  let upstream = process.new_subject()
  let assert Ok(_logger) = stage_logger.start([upstream])

  let assert Ok(envelope.Control(envelope.Subscribe(from: _))) =
    process.receive(upstream, within: 50)
}

pub fn logger_stops_on_control_message_test() {
  process.trap_exits(True)
  let upstream = process.new_subject()
  let assert Ok(logger) = stage_logger.start([upstream])
  let selector =
    process.new_selector()
    |> process.select_trapped_exits(fn(exit) { exit })

  process.send(
    logger,
    envelope.Control(envelope.Subscribe(process.new_subject())),
  )

  let assert Ok(process.ExitMessage(pid: _, reason: reason)) =
    process.selector_receive(selector, within: 50)

  case reason {
    process.Abnormal(_) -> Nil
    _ -> panic as "Expected abnormal exit"
  }

  process.trap_exits(False)
}
