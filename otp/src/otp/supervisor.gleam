import gleam/erlang/process.{type Subject}
import gleam/function
import gleam/int
import gleam/otp/actor
import gleam/otp/static_supervisor as sup
import gleam/otp/supervisor
import prng/random

pub fn run_actor_ex1(
  parent: Subject(Subject(MessageEx1)),
  worker: Subject(MessageEx1),
  times: Int,
) -> Subject(MessageEx1) {
  case times {
    0 -> worker
    _ -> {
      case play_game_ex1(worker) {
        Ok(_) -> {
          echo "success!"
          run_actor_ex1(parent, worker, times - 1)
        }
        Error(_) -> {
          echo "Crash!"
          let assert Ok(new_worker) = process.receive(parent, 1000)
          run_actor_ex1(parent, new_worker, times - 1)
        }
      }
    }
  }
}

pub fn start_ex1(_arg: Nil, parent: Subject(Subject(MessageEx1))) {
  actor.start_spec(actor.Spec(
    init: fn() {
      let subj = process.new_subject()
      process.send(parent, subj)

      let selector =
        process.new_selector()
        |> process.selecting(subj, function.identity)

      actor.Ready(Nil, selector)
    },
    init_timeout: 1000,
    loop: handle_message_ex1,
  ))
}

pub fn play_game_ex1(
  subject: Subject(MessageEx1),
) -> Result(String, process.CallError(String)) {
  let msg_generator = random.weighted(#(9.0, Good), [#(1.0, Bad)])
  let msg = random.random_sample(msg_generator)

  process.try_call(subject, msg, 1000)
}

pub type MessageEx1 {
  Good(client: Subject(String))
  Bad(client: Subject(String))
  Shutdown
}

pub fn handle_message_ex1(msg: MessageEx1, _state: Nil) {
  case msg {
    Good(client) -> {
      actor.send(client, "duck")
      actor.continue(Nil)
    }
    Bad(_) -> panic as "Oh no!"
    Shutdown -> actor.Stop(process.Normal)
  }
}

pub type StateEx2 {
  StateEx2(
    id: String,
    count: Int,
    crash_after: Int,
    subject: Subject(MessageEx2),
  )
}

pub type MessageEx2 {
  Tick
}

const tick_interval_ms = 1000

pub fn worker_init_ex2(id: String) -> actor.InitResult(StateEx2, MessageEx2) {
  // Determine a random number of ticks before this instance crashes
  let crash_point = random.int(3, 12) |> random.random_sample()
  echo id
  <> " starting! Will crash after "
  <> int.to_string(crash_point)
  <> " ticks."

  let self_subject = process.new_subject()

  process.send_after(self_subject, 0, Tick)

  let initial_state =
    StateEx2(id: id, count: 0, crash_after: crash_point, subject: self_subject)

  let selector =
    process.new_selector()
    |> process.selecting(self_subject, function.identity)

  actor.Ready(initial_state, selector)
}

pub fn handle_tick_ex2(
  message: MessageEx2,
  state: StateEx2,
) -> actor.Next(MessageEx2, StateEx2) {
  case message {
    Tick -> {
      let new_count = state.count + 1
      echo {
        state.id
        <> " ticked "
        <> int.to_string(new_count)
        <> " times (target: "
        <> int.to_string(state.crash_after)
        <> ")"
      }
      case new_count >= state.crash_after {
        True -> {
          echo { state.id <> " crashing as planned!" }
          panic as { "Worker " <> state.id <> " reached its crash point." }
        }
        False -> {
          process.send_after(state.subject, tick_interval_ms, Tick)
          actor.continue(StateEx2(..state, count: new_count))
        }
      }
    }
  }
}

pub fn create_worker_starter_ex2(id: String) -> fn() -> actor.ErlangStartResult {
  fn() {
    let spec =
      actor.Spec(
        init: fn() { worker_init_ex2(id) },
        init_timeout: 5000,
        loop: handle_tick_ex2,
      )
    actor.start_spec(spec)
    |> actor.to_erlang_start_result
  }
}

pub fn main() {
  example1()
  example2()
}

pub fn example1() {
  let parent_subject = process.new_subject()

  let worker = supervisor.worker(start_ex1(_, parent_subject))

  let children = fn(children) {
    children
    |> supervisor.add(worker)
  }

  let assert Ok(_) =
    supervisor.start_spec(supervisor.Spec(
      argument: Nil,
      frequency_period: 1,
      max_frequency: 100,
      init: children,
    ))
  let assert Ok(worker_subj) = process.receive(parent_subject, 1000)

  run_actor_ex1(parent_subject, worker_subj, 10)
}

pub fn example2() {
  let start_worker_1 = create_worker_starter_ex2("worker_1")
  let start_worker_2 = create_worker_starter_ex2("worker_2")

  let supervisor_spec =
    sup.new(sup.OneForOne)
    |> sup.add(sup.worker_child(id: "worker_1", run: start_worker_1))
    |> sup.add(sup.worker_child(id: "worker_2", run: start_worker_2))
    |> sup.restart_tolerance(intensity: 10, period: 10)

  let assert Ok(supervisor_pid) = sup.start_link(supervisor_spec)
  echo supervisor_pid

  process.sleep(10_000)
  process.send_exit(supervisor_pid)
  echo "supervisor exited"
  process.sleep(1000)
  echo "bye!"
}
