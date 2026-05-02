import app/context.{type Context}
import app/error.{QueryFailed, RecordNotFound}
import gleam/json
import gleam/option
import gleam/result
import repositories/contacts/repository as contacts_repository
import shared/contacts/contact
import shared/contacts/repository.{
  type ListParams, Descending, ListParams, SortByCreatedAt,
}
import shared/repository.{type Error, DatabaseError, NotFound}
import web

import wisp.{type Request, type Response}

fn repo_error(err: Error) -> error.DatabaseError {
  case err {
    NotFound(_) -> RecordNotFound
    DatabaseError(msg) -> QueryFailed(msg)
  }
}

pub fn list_contacts(_request: Request, ctx: Context) -> Response {
  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let params =
    ListParams(
      stage: option.None,
      company: option.None,
      search: option.None,
      email: option.None,
      phone: option.None,
      title: option.None,
      sort_by: SortByCreatedAt,
      sort_direction: Descending,
      cursor: option.None,
      limit: 30,
    )
  use contacts <- web.db_execute(
    repo.list(params) |> result.map_error(repo_error),
  )

  contacts
  |> json.array(contact.to_json)
  |> json.to_string
  |> wisp.json_body(wisp.ok(), _)
}
