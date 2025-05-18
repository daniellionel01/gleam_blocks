import gleam/result

pub fn main() {
  let _ = example1()
}

/// When using the `use` syntax sugar we need to return the same error type
/// in all `use` statements
pub fn example1() {
  use a <- result.try(result_a())
  use b <- result.try(
    result_b()
    |> result.replace_error(Nil),
  )

  Ok(Nil)
}

fn result_a() -> Result(Int, Nil) {
  Ok(1)
}

fn result_b() -> Result(Int, String) {
  Ok(1)
}
