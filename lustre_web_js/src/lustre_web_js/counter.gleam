// IMPORTS ---------------------------------------------------------------------

import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/result
import lustre.{type App}
import lustre/attribute
import lustre/component
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event

pub const name = "my-counter"

pub fn element(attributes: List(attribute.Attribute(msg))) -> Element(msg) {
  element.element(name, attributes, [])
}

/// It's good practice to provide any custom attributes you want to support as
/// functions consumers of this component can call. Where possible, it's preferable
/// to use string attributes rather than rich properties so they can also be used
/// when server-rendering the component's HTML.
///
pub fn value(value: Int) -> attribute.Attribute(msg) {
  attribute.value(int.to_string(value))
}

/// Providing event attributes can be convenient don't need to know the exact
/// shape of the `detail` property on your component's custom events. Additionally,
/// you may want to provide the decoder itself in case users want to write their
/// own event listeners.
///
pub fn on_change(handler: fn(Int) -> msg) -> attribute.Attribute(msg) {
  event.on("change", {
    decode.at(["detail"], decode.int) |> decode.map(handler)
  })
}

pub fn register() -> Result(Nil, lustre.Error) {
  lustre.register(app(), name)
}

pub fn app() -> App(Nil, Model, Msg) {
  lustre.component(init, update, view, [
    component.on_attribute_change("value", fn(value) {
      int.parse(value) |> result.map(Reset)
    }),
    component.on_property_change("value", { decode.int |> decode.map(Reset) }),
  ])
}

// MODEL -----------------------------------------------------------------------

pub type Model =
  Int

pub fn init(_) -> #(Model, Effect(Msg)) {
  let model = 0
  let effect = effect.none()

  #(model, effect)
}

// UPDATE ----------------------------------------------------------------------

pub type Msg {
  Incr
  Decr
  Reset(Int)
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    Incr -> {
      let model = model + 1
      let effect = event.emit("incr", json.int(model))

      #(model, effect)
    }

    Decr -> {
      let model = model - 1
      let effect = event.emit("decr", json.int(model))

      #(model, effect)
    }

    Reset(count) -> #(count, effect.none())
  }
}

// VIEW ------------------------------------------------------------------------

pub fn view(model: Model) -> Element(Msg) {
  let count = int.to_string(model)

  html.div([], [
    html.button([event.on_click(Incr)], [html.text("+")]),
    html.div([], [html.span([], [html.text(count)])]),
    html.button([event.on_click(Decr)], [html.text("-")]),
  ])
}
