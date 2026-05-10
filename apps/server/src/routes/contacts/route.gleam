import app/context.{type Context}
import gleam/http.{Delete, Get, Patch, Post}
import gleam/json
import gleam/option
import repositories/contacts/repository as contacts_repository
import routes/contacts/list_params
import shared/contacts/contact
import shared/pagination
import web
import wisp.{type Request, type Response}

pub fn handler(segments: List(String), req: Request, ctx: Context) -> Response {
  case segments {
    [] ->
      case req.method {
        Get -> list(req, ctx)
        Post -> create(req, ctx)
        _ -> wisp.method_not_allowed([Get, Post])
      }
    [id] ->
      case req.method {
        Get -> show(req, ctx, id)
        Patch -> update(req, ctx, id)
        Delete -> delete(req, ctx, id)
        _ -> wisp.method_not_allowed([Get, Patch, Delete])
      }
    _ -> wisp.not_found()
  }
}

fn create(req: Request, ctx: Context) -> Response {
  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  use body <- wisp.require_json(req)
  use input <- web.decode_body(body, contact.input_decoder())
  use created <- web.db_execute(repo.create(input))

  created
  |> contact.to_json
  |> json.to_string
  |> wisp.json_body(wisp.created(), _)
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

fn show(_req: Request, ctx: Context, id: String) -> Response {
  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  use id <- web.parse_id(id)
  use found <- web.db_execute(repo.get(id))

  found
  |> contact.to_json
  |> json.to_string
  |> wisp.json_body(wisp.ok(), _)
}

fn update(req: Request, ctx: Context, id: String) -> Response {
  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  use id <- web.parse_id(id)
  use body <- wisp.require_json(req)
  use input <- web.decode_body(body, contact.input_decoder())
  use updated <- web.db_execute(repo.update(contact.to_contact(id, input)))

  updated
  |> contact.to_json
  |> json.to_string
  |> wisp.json_body(wisp.ok(), _)
}

fn delete(_req: Request, ctx: Context, id: String) -> Response {
  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  use id <- web.parse_id(id)
  use _ <- web.db_execute(repo.delete(id))

  wisp.no_content()
}
