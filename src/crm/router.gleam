import crm/web
import gleam/http
import wisp.{type Request, type Response}

pub fn handle_request(req: Request) -> Response {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    [] -> home_page(req)
    _ -> wisp.not_found()
  }
}

fn home_page(req: Request) -> Response {
  use <- wisp.require_method(req, http.Get)
  wisp.ok()
  |> wisp.html_body("
    <!DOCTYPE html>
    <html>
      <head><title>CRM</title></head>
      <body>
        <h1>Hello CRM</h1>
        <p>The Gleam CRM is running.</p>
      </body>
    </html>
  ")
}
