import gleam/http/request.{type Request}
import wisp
import wisp/internal


pub fn middleware(
  req: Request(internal.Connection),
  handle_request: fn(Request(internal.Connection)) -> wisp.Response,
) -> wisp.Response {
  let req = wisp.method_override(req)
  use <- wisp.log_request(req)
  use <- wisp.rescue_crashes
  use req <- wisp.handle_head(req)
  // CSRF protection is important for state-changing requests
  // use req <- wisp.csrf_known_header_protection(req)
  handle_request(req)
}
