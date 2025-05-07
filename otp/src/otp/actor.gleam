import gleam/erlang/process.{type Subject}
import gleam/otp/actor

pub type Ex1Message {
  Inc(by: Int)
  Current(caller: Subject(Int))
}

pub type Ex2Message(a) {
  Push(item: a)
  Pop(reply_with: Subject(Result(a, Nil)))
  Shutdown
}

pub fn main() {
  example1()
  let _ = example2()
}

/// Simple counter actor
pub fn example1() {
  let loop = fn(msg: Ex1Message, state: Int) {
    case msg {
      Inc(by) -> actor.continue(state + by)
      Current(caller) -> {
        process.send(caller, state)
        actor.continue(state)
      }
    }
  }

  let assert Ok(subject) = actor.start(0, loop)
  process.send(subject, Inc(by: 3))
  process.send(subject, Inc(by: 7))

  process.call(subject, fn(c) { Current(c) }, 5)
  |> echo
}

/// Simple stack actor with shutdown message
pub fn example2() {
  let handle = fn(msg: Ex2Message(a), state: List(a)) {
    case msg {
      Push(item) -> {
        let new_state = [item, ..state]
        actor.continue(new_state)
      }
      Pop(caller) -> {
        case state {
          [] -> {
            actor.send(caller, Error(Nil))
            actor.continue([])
          }
          [item, ..rest] -> {
            actor.send(caller, Ok(item))
            actor.continue(rest)
          }
        }
      }
      Shutdown -> actor.Stop(process.Normal)
    }
  }

  let assert Ok(subject) = actor.start([], handle)

  process.send(subject, Push(3))

  let popped = actor.call(subject, Pop, 1000)
  let _ = echo popped

  let popped = actor.call(subject, Pop, 1000)
  echo popped
}
