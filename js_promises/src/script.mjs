import * as $gleam from "./gleam.mjs";

export function simpleNumber() {
  return new Promise((r) => r(3));
}

export async function throwPromise() {
  throw new Error("oops");
}

export async function resultPromise(fail) {
  if (fail === false) {
    return new $gleam.Ok(3);
  } else if (fail === true) {
    return new $gleam.Error(0);
  }
}

export async function mightFail() {
  if (Math.random() <= 0.3) {
    throw new Error("unlucky");
  } else {
    return 3;
  }
}
