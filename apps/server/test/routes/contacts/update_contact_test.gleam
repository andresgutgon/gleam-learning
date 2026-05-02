import app/context
import gleam/http
import gleam/int
import gleam/json
import repositories/contacts/repository as contacts_repository
import router
import shared/contacts/contact.{type Contact}
import support/app/test_context
import support/app/test_database
import support/factories/contact as contact_factory
import wisp/simulate

fn contact_input_json(c: Contact) -> json.Json {
  json.object([
    #("first_name", json.string(c.first_name)),
    #("last_name", json.string(c.last_name)),
    #("email", json.string(c.email)),
    #("phone", json.nullable(c.phone, json.string)),
    #("company", json.nullable(c.company, json.string)),
    #("title", json.nullable(c.title, json.string)),
    #("stage", json.string(stage_to_string(c.stage))),
    #("profile_picture_url", json.nullable(c.profile_picture_url, json.string)),
    #("notes", json.nullable(c.notes, json.string)),
  ])
}

fn stage_to_string(stage: contact.PipelineStage) -> String {
  case stage {
    contact.CustomerStage -> "Customer"
    contact.OpportunityStage -> "Opportunity"
    contact.ContactStage -> "Contact"
    contact.LeadStage -> "Lead"
  }
}

pub fn update_contact_success_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(created) =
    contact_factory.new() |> contact_factory.build() |> repo.create

  let input =
    contact_input_json(contact.Contact(..created, first_name: "Updated"))

  let response =
    simulate.request(http.Patch, "/api/contacts/" <> int.to_string(created.id))
    |> simulate.json_body(input)
    |> router.handle_request(ctx)

  assert response.status == 200

  let assert Ok(updated) =
    simulate.read_body(response) |> json.parse(contact.decoder())

  assert updated.id == created.id
  assert updated.first_name == "Updated"
}

pub fn update_contact_not_found_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(created) =
    contact_factory.new() |> contact_factory.build() |> repo.create

  let input = contact_input_json(created)

  let response =
    simulate.request(http.Patch, "/api/contacts/999999")
    |> simulate.json_body(input)
    |> router.handle_request(ctx)

  assert response.status == 404
}

pub fn update_contact_invalid_id_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(created) =
    contact_factory.new() |> contact_factory.build() |> repo.create

  let input = contact_input_json(created)

  let response =
    simulate.request(http.Patch, "/api/contacts/not-an-id")
    |> simulate.json_body(input)
    |> router.handle_request(ctx)

  assert response.status == 404
}

pub fn update_contact_invalid_body_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(created) =
    contact_factory.new() |> contact_factory.build() |> repo.create

  let response =
    simulate.request(http.Patch, "/api/contacts/" <> int.to_string(created.id))
    |> simulate.json_body(json.object([]))
    |> router.handle_request(ctx)

  assert response.status == 422
}
