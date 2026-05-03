import app/context
import gleam/http
import gleam/int
import repositories/contacts/repository as contacts_repository
import router
import support/app/test_context
import support/app/test_database
import support/factories/contact as contact_factory
import wisp/simulate

pub fn delete_contact_success_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(created) =
    contact_factory.new() |> contact_factory.build() |> repo.create

  let response =
    simulate.request(http.Delete, "/api/contacts/" <> int.to_string(created.id))
    |> router.handle_request(ctx)

  assert response.status == 204
}

pub fn delete_contact_not_found_test() {
  let ctx = test_context.get()

  let response =
    simulate.request(http.Delete, "/api/contacts/999999")
    |> router.handle_request(ctx)

  assert response.status == 404
}

pub fn delete_contact_invalid_id_test() {
  let ctx = test_context.get()

  let response =
    simulate.request(http.Delete, "/api/contacts/not-an-id")
    |> router.handle_request(ctx)

  assert response.status == 404
}
