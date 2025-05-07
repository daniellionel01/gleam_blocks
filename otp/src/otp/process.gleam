import gleam/erlang/process
import gleam/function
import gleam/int

pub fn main() {
  example1()
  example2()
  example3()
  example4()
}

/// Process as the lowest level concurrency building block
pub fn example1() {
  let pid =
    process.start(
      running: fn() {
        { 3 + 4 }
        |> echo
      },
      linked: True,
    )
  echo pid
}

/// Subjects are basically just messages
pub fn example2() {
  let subj = process.new_subject()
  process.start(fn() { process.send(subj, "Hello you!") }, True)
  let assert Ok(msg) = process.receive(subj, 1000)
  echo msg
}

/// The order of subjects does not matter
pub fn example3() {
  let subj = process.new_subject()
  let subj2 = process.new_subject()

  process.start(
    fn() {
      process.send(subj, "Hello you!")
      process.send(subj2, "Hello you 2!")
    },
    True,
  )
  let assert Ok(msg) = process.receive(subj2, 1000)
  echo msg

  let assert Ok(msg) = process.receive(subj, 1000)
  echo msg
}

/// Selectors allow you to receive messages over multiple subjects
/// They are selected in the order they come in (FIFO)
pub fn example4() {
  let string_subj = process.new_subject()
  let int_subj = process.new_subject()

  let selector =
    process.new_selector()
    |> process.selecting(string_subj, function.identity)
    |> process.selecting(int_subj, int.to_string)

  process.send(int_subj, 1)
  process.send(string_subj, "2")

  let assert Ok(num) = process.select(selector, 1000)
  echo num

  let assert Ok(msg) = process.select(selector, 1000)
  echo msg
}
