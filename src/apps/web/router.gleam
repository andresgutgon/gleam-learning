import apps/web/middleware
import apps/web/routes/contacts
import apps/web/routes/home
import gleam/http/request.{type Request}
import infra.{type AppContext}
import wisp
import wisp/internal

pub fn handle_request(
  req: Request(internal.Connection),
  ctx: AppContext,
) -> wisp.Response {
  use req <- middleware.middleware(req)

  case wisp.path_segments(req) {
    [] -> home.handle(req)
    ["contacts", ..rest] -> contacts.handle(req, rest, ctx)
    _ -> wisp.not_found()
  }
}
