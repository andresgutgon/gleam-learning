import gleam/http
import gleam/json
import gleam/option.{Some}
import router
import shared/contacts/contact
import support/app/test_context
import support/app/test_database
import support/factories/contact as contact_factory
import wisp/simulate

fn contact_input_json(c: contact.ContactInput) -> json.Json {
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

pub fn create_contact_success_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let input =
    contact_factory.new()
    |> contact_factory.with_first_name("Alice")
    |> contact_factory.with_last_name("Smith")
    |> contact_factory.with_stage(contact.CustomerStage)
    |> contact_factory.with_company("Acme")
    |> contact_factory.build()

  let response =
    simulate.request(http.Post, "/api/contacts")
    |> simulate.json_body(contact_input_json(input))
    |> router.handle_request(ctx)

  assert response.status == 201

  let assert Ok(created) =
    simulate.read_body(response) |> json.parse(contact.decoder())

  assert created.id > 0
  assert created.first_name == "Alice"
  assert created.last_name == "Smith"
  assert created.stage == contact.CustomerStage
  assert created.company == Some("Acme")
  assert created.email == input.email
}

pub fn create_contact_invalid_body_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let response =
    simulate.request(http.Post, "/api/contacts")
    |> simulate.json_body(json.object([]))
    |> router.handle_request(ctx)

  assert response.status == 422
}
