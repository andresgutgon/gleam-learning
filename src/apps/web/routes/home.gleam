import gleam/http
import gleam/http/request.{type Request}
import wisp
import wisp/internal

pub fn handle(req: Request(internal.Connection)) -> wisp.Response {
  use <- wisp.require_method(req, http.Get)
  wisp.ok()
  |> wisp.html_body(
    "<!DOCTYPE html><html><head><title>CRM</title></head><body><h1>Hello CRM v2!</h1><p>The Gleam CRM is running. NEW CODE!</p></body></html>",
  )
}
