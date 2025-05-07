import gleam/erlang
import gleam/erlang/process
import gleam/list
import gleam/otp/task.{type Task}

pub fn main() {
  example1()
  let _ = example2()
  example3()
  example4()
}

fn calculate() {
  process.sleep(1000)
  "calculation!"
}

fn double(n: Int) {
  n * 2
}

/// Tasks are effectively single use processes that execute a function and return its result
pub fn example1() {
  let my_task: Task(String) = task.async(calculate)
  // ... do other work...
  task.await(my_task, 10_000)
  |> echo
}

/// You can catch timeout errors of tasks
pub fn example2() {
  let my_task: Task(String) = task.async(calculate)
  // ... do other work...
  task.try_await(my_task, 100)
  |> echo
}

/// Fan Out - Fan In Pattern
pub fn example3() {
  [1, 2, 3]
  |> list.map(fn(n) { task.async(fn() { double(n) }) })
  |> list.map(fn(h) { task.try_await(h, 1000) })
  |> echo
}

/// Rescuing from a panic
pub fn example4() {
  let work = fn() {
    echo "doing some work"
    panic as "something went wrong"
  }
  let task = task.async(fn() { erlang.rescue(work) })

  let _ =
    task.await_forever(task)
    |> echo
}
