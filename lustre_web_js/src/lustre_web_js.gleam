import gleam/int
import lustre
import lustre/element
import lustre/element/html
import lustre/event

pub fn main() -> Nil {
  let app = lustre.simple(init, update, view)
  let assert Ok(_) = lustre.start(app, "#app", Nil)

  Nil
}

type Model =
  Int

fn init(_) -> Model {
  0
}

type Message {
  Incr
  Decr
}

fn update(model: Model, msg: Message) -> Model {
  case msg {
    Decr -> model - 1
    Incr -> model + 1
  }
}

fn view(model: Model) -> element.Element(Message) {
  let count = int.to_string(model)

  html.div([], [
    html.button([event.on_click(Decr)], [html.text("-")]),
    html.p([], [html.text("count: "), html.text(count)]),
    html.button([event.on_click(Incr)], [html.text("+")]),
  ])
}
