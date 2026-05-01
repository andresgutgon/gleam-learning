import gleam/http
import gleam/http/request.{type Request}
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import infra.{type AppContext}
import packages/domain/contacts/repository.{
  type Contact, Descending, ListParams, NotFound, SortByCreatedAt,
}
import packages/platform/postgresql/repositories/contacts/repository as contacts_repo
import wisp
import wisp/internal

pub fn handle(
  req: Request(internal.Connection),
  segments: List(String),
  ctx: AppContext,
) -> wisp.Response {
  let repo = contacts_repo.new(ctx.db)
  case segments {
    [] -> list(req, repo)
    [id] -> show(req, id, repo)
    _ -> wisp.not_found()
  }
}

fn list(
  req: Request(internal.Connection),
  repo: repository.Repository,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)
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
  case repo.list(params) {
    Ok(result) -> wisp.ok() |> wisp.html_body(list_html(result.contacts))
    Error(err) -> {
      wisp.log_error("Failed to list contacts: " <> string.inspect(err))
      wisp.internal_server_error()
    }
  }
}

fn show(
  req: Request(internal.Connection),
  id: String,
  repo: repository.Repository,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)
  case int.parse(id) {
    Ok(contact_id) ->
      case repo.get(contact_id) {
        Ok(contact) -> wisp.ok() |> wisp.html_body(detail_html(contact))
        Error(NotFound(_)) -> wisp.not_found()
        Error(_) -> wisp.internal_server_error()
      }
    Error(_) -> wisp.bad_request("")
  }
}

fn list_html(contacts: List(Contact)) -> String {
  "<h1>Contacts</h1><ul>"
  <> list.map(contacts, fn(c) {
    "<li><a href=\"/contacts/"
    <> int.to_string(c.id)
    <> "\">"
    <> c.first_name
    <> " "
    <> c.last_name
    <> "</a></li>"
  })
  |> string.join("")
  <> "</ul>"
}

fn detail_html(contact: Contact) -> String {
  "<h1>Contact Details</h1>"
  <> "<p>ID: "
  <> int.to_string(contact.id)
  <> "</p>"
  <> "<p>Name: "
  <> contact.first_name
  <> " "
  <> contact.last_name
  <> "</p>"
  <> "<p>Email: "
  <> contact.email
  <> "</p>"
}
