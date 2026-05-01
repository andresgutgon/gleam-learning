import apps/web/middleware
import gleam/http
import gleam/http/request.{type Request}
import gleam/int
import gleam/list
import gleam/option
import gleam/string
import packages/domain/contacts/repository.{
  type Contact, type Repository, Descending, ListParams, NotFound,
  SortByCreatedAt,
}
import wisp
import wisp/internal

pub type AppConfig {
  AppConfig(contacts_repo: Repository)
}

pub fn handle_request(
  req: Request(internal.Connection),
  config: AppConfig,
) -> wisp.Response {
  // Apply middleware
  use req <- middleware.middleware(req)

  // Route matching
  let segments = wisp.path_segments(req)
  case segments {
    [] -> home_page(req)
    ["contacts"] -> contacts_page(req, config)
    ["contacts", id] -> contact_page(req, id, config)
    other -> {
      // Return a debug response to see what path we got
      wisp.response(404)
      |> wisp.html_body(
        "<h1>404 Not Found</h1><p>Path: " <> string.inspect(other) <> "</p>",
      )
    }
  }
}

fn home_page(req: Request(internal.Connection)) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)
  wisp.ok()
  |> wisp.html_body(
    "<!DOCTYPE html><html><head><title>CRM</title></head><body><h1>Hello CRM v2!</h1><p>The Gleam CRM is running. NEW CODE!</p></body></html>",
  )
}

fn contacts_page(
  req: Request(internal.Connection),
  config: AppConfig,
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
  case config.contacts_repo.list(params) {
    Ok(result) -> {
      let contacts_html = list_contacts_html(result.contacts)
      wisp.ok() |> wisp.html_body(contacts_html)
    }
    Error(err) -> {
      wisp.log_error("Failed to list contacts: " <> string.inspect(err))
      wisp.internal_server_error()
    }
  }
}

fn contact_page(
  req: Request(internal.Connection),
  id: String,
  config: AppConfig,
) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)
  case int.parse(id) {
    Ok(contact_id) -> {
      case config.contacts_repo.get(contact_id) {
        Ok(contact) -> wisp.ok() |> wisp.html_body(contact_detail_html(contact))
        Error(NotFound(_)) -> wisp.not_found()
        Error(_) -> wisp.internal_server_error()
      }
    }
    Error(_) -> wisp.bad_request("")
  }
}

fn list_contacts_html(contacts: List(Contact)) -> String {
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

fn contact_detail_html(contact: Contact) -> String {
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
  // ... more details
}
