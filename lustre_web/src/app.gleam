import gleam/erlang/process
import gleam/http.{Get}
import lustre/attribute as attr
import lustre/element
import lustre/element/html
import mist
import wisp.{type Request, type Response}
import wisp/wisp_mist

pub type Context {
  Context(static_directory: String)
}

pub fn main() -> Nil {
  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  let ctx = Context(static_directory())

  let assert Ok(_) =
    wisp_mist.handler(handle_request(_, ctx), secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start_http

  process.sleep_forever()
}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- middleware(req, ctx)

  use <- wisp.require_method(req, Get)

  case wisp.path_segments(req) {
    [] ->
      home_page()
      |> layout()
      |> serve_html

    _ -> wisp.not_found()
  }
}

pub fn serve_html(el: element.Element(a)) -> wisp.Response {
  el
  |> element.to_document_string_tree
  |> wisp.html_response(200)
}

fn home_page() -> element.Element(a) {
  html.div([], [
    html.p([], [html.text("home")]),
    element.element("my-counter", [attr.attribute("value", "3")], []),
  ])
}

pub fn middleware(
  req: wisp.Request,
  ctx: Context,
  handle_request: fn(wisp.Request) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  use <- wisp.serve_static(req, under: "/static", from: ctx.static_directory)

  handle_request(req)
}

pub fn static_directory() -> String {
  let assert Ok(priv_directory) = wisp.priv_directory("app")
  priv_directory
}

pub fn layout(element: element.Element(t)) -> element.Element(t) {
  html.html([], [
    html.head([], [
      html.title([], "Gleam Blocks"),
      html.meta([
        attr.name("viewport"),
        attr.content("width=device-width, initial-scale=1"),
      ]),
      html.link([attr.rel("preconnect"), attr.href("https://fonts.bunny.net")]),
      html.link([
        attr.rel("stylesheet"),
        attr.href(
          "https://fonts.bunny.net/css?family=inter:100,100i,200,200i,300,300i,400,400i,500,500i,600,600i,700,700i,800,800i,900,900i",
        ),
      ]),
      html.link([attr.rel("stylesheet"), attr.href("/static/app.css")]),
      html.script([attr.src("/static/counter.mjs"), attr.type_("module")], ""),
    ]),
    html.body([], [element]),
  ])
}
