import gleam/int
import gleam/io
import gleam/javascript/promise
import gleam/list

@external(javascript, "./script.mjs", "simpleNumber")
pub fn simple_number() -> promise.Promise(Int)

@external(javascript, "./script.mjs", "throwPromise")
pub fn throw_promise() -> promise.Promise(Int)

@external(javascript, "./script.mjs", "resultPromise")
pub fn result_promise(fail: Bool) -> promise.Promise(Result(Int, Int))

@external(javascript, "./script.mjs", "mightFail")
pub fn might_fail() -> promise.Promise(Int)

pub fn main() {
  let _ = example1()
  let _ = example2()
  let _ = example3()
  let _ = example4()
  let _ = example5()
}

pub fn example1() {
  let prom = simple_number()
  promise.map(prom, fn(v) { echo v })
}

pub fn example2() {
  let prom = simple_number()
  use v <- promise.map(prom)
  echo v
}

pub fn example3() {
  let prom = throw_promise()
  prom
  |> promise.rescue(fn(e) {
    echo e
    0
  })
  |> promise.map(fn(v) { echo v })
}

pub fn example4() {
  let p = result_promise(False)

  use res <- promise.map(p)

  case res {
    Ok(v) -> io.println("ok: " <> int.to_string(v))
    Error(v) -> io.println("err: " <> int.to_string(v))
  }
}

pub fn example5() {
  list.repeat("", 10)
  |> list.each(fn(_) {
    let p =
      might_fail()
      |> promise.rescue(fn(_) { 999 })

    use res <- promise.map(p)

    echo res
  })
}
