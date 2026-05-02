import app/context.{type Context}
import routes/contacts/route as contacts
import web
import wisp.{type Request, type Response}

pub fn handle_request(req: Request, ctx: Context) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["api", "contacts", ..rest] -> contacts.handler(rest, req, ctx)
    _ -> wisp.not_found()
  }
}
