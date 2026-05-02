import app/context.{type Context}
import gleam/http.{Delete, Get, Patch}
import gleam/option
import repositories/contacts/repository as contacts_repository
import routes/contacts/list_params
import shared/contacts/contact
import shared/pagination
import web
import wisp.{type Request, type Response}

pub fn handler(segments: List(String), req: Request, ctx: Context) -> Response {
  case segments, req.method {
    [], Get -> list(req, ctx)
    [_], _ -> wisp.method_not_allowed([Get, Patch, Delete])
    _, _ -> wisp.not_found()
  }
}

fn list(request: Request, ctx: Context) -> Response {
  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  use result <- web.db_execute(repo.list(list_params.from_request(request)))
  web.page_response(
    result.data,
    option.map(result.next_cursor, pagination.encode_cursor),
    contact.to_json,
  )
}
