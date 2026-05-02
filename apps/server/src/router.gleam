import context.{type Context}
import gleam/http.{Delete, Get, Patch, Post}
import routes/contacts as contact_routes
import web
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["api", "contacts", ..rest] -> handle_tasks(rest, req, ctx)
    _ -> wisp.not_found()
  }
}

fn handle_tasks(
  segments: List(String),
  req: Request,
  ctx: Context,
) -> Response {
  case segments, req.method {
    [], Get -> contact_routes.list_tasks(ctx)
    [_], _ -> wisp.method_not_allowed([Get, Patch, Delete])
    _, _ -> wisp.not_found()
  }
}
