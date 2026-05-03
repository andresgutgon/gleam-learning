import gleam/http
import router
import support/app/test_context
import wisp/simulate

pub fn unknown_route_not_found_test() {
  let ctx = test_context.get()

  let response =
    simulate.request(http.Get, "/unknown")
    |> router.handle_request(ctx)

  assert response.status == 404
  assert simulate.read_body(response) == "Not found"
}

pub fn nested_contacts_route_not_found_test() {
  let ctx = test_context.get()

  let response =
    simulate.request(http.Get, "/api/contacts/1/subtasks")
    |> router.handle_request(ctx)

  assert response.status == 404
  assert simulate.read_body(response) == "Not found"
}

pub fn contacts_put_not_allowed_test() {
  let ctx = test_context.get()

  let response =
    simulate.request(http.Put, "/api/contacts")
    |> router.handle_request(ctx)

  assert response.status == 405
  assert simulate.read_body(response) == "Method not allowed"
}

pub fn contact_by_id_post_not_allowed_test() {
  let ctx = test_context.get()

  let response =
    simulate.request(http.Post, "/api/contacts/1")
    |> router.handle_request(ctx)

  assert response.status == 405
  assert simulate.read_body(response) == "Method not allowed"
}
