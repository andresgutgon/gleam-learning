import app/context
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/uri
import repositories/contacts/repository as contacts_repository
import router
import shared/contacts/contact
import shared/pagination
import support/app/test_context
import support/app/test_database
import support/factories/contact as contact_factory
import wisp/simulate

// --- Response decoders ---

fn page_decoder() {
  use data <- decode.field("data", decode.list(contact.decoder()))
  use next_cursor <- decode.field(
    "next_cursor",
    decode.optional(cursor_decoder()),
  )
  decode.success(#(data, next_cursor))
}

fn cursor_decoder() -> decode.Decoder(pagination.Cursor) {
  use value <- decode.field("value", decode.string)
  use id <- decode.field("id", decode.int)
  decode.success(pagination.Cursor(value:, id:))
}

fn cursor_to_param(cursor: pagination.Cursor) -> String {
  pagination.encode_cursor(cursor)
  |> json.to_string
  |> uri.percent_encode
}

// --- Tests ---

pub fn empty_list_contacts_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let response =
    simulate.request(http.Get, "/api/contacts")
    |> router.handle_request(ctx)

  assert response.status == 200

  let body = simulate.read_body(response)
  let assert Ok(#(contacts, next_cursor)) = json.parse(body, page_decoder())

  assert contacts == []
  assert next_cursor == None
}

pub fn list_contacts_returns_created_contacts_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.build()
    |> repo.create

  let response =
    simulate.request(http.Get, "/api/contacts")
    |> router.handle_request(ctx)

  assert response.status == 200

  let body = simulate.read_body(response)
  let assert Ok(#(contacts, _)) = json.parse(body, page_decoder())

  assert list.length(contacts) == 3
}

pub fn list_contacts_filter_by_stage_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_stage(contact.LeadStage)
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_stage(contact.CustomerStage)
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_stage(contact.LeadStage)
    |> contact_factory.build()
    |> repo.create

  let response =
    simulate.request(http.Get, "/api/contacts?stage=lead")
    |> router.handle_request(ctx)

  assert response.status == 200

  let body = simulate.read_body(response)
  let assert Ok(#(contacts, _)) = json.parse(body, page_decoder())

  assert list.length(contacts) == 2
  assert list.all(contacts, fn(c) { c.stage == contact.LeadStage })
}

pub fn list_contacts_filter_by_company_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_company("Acme Corp")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_company("Tech Inc")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_company("Acme Ltd")
    |> contact_factory.build()
    |> repo.create

  let response =
    simulate.request(http.Get, "/api/contacts?company=Acme")
    |> router.handle_request(ctx)

  assert response.status == 200

  let body = simulate.read_body(response)
  let assert Ok(#(contacts, _)) = json.parse(body, page_decoder())

  assert list.length(contacts) == 2
}

pub fn list_contacts_filter_by_search_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("John")
    |> contact_factory.with_last_name("Smith")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("Jane")
    |> contact_factory.with_last_name("Johnson")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("Bob")
    |> contact_factory.with_last_name("Williams")
    |> contact_factory.build()
    |> repo.create

  let response =
    simulate.request(http.Get, "/api/contacts?search=John")
    |> router.handle_request(ctx)

  assert response.status == 200

  let body = simulate.read_body(response)
  let assert Ok(#(contacts, _)) = json.parse(body, page_decoder())

  // Matches "John" (first name) and "Johnson" (last name)
  assert list.length(contacts) == 2
}

pub fn list_contacts_sort_by_first_name_asc_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("Charlie")
    |> contact_factory.with_email("c@example.com")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("Alice")
    |> contact_factory.with_email("a@example.com")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("Bob")
    |> contact_factory.with_email("b@example.com")
    |> contact_factory.build()
    |> repo.create

  let response =
    simulate.request(
      http.Get,
      "/api/contacts?sort_by=first_name&sort_direction=asc",
    )
    |> router.handle_request(ctx)

  assert response.status == 200

  let body = simulate.read_body(response)
  let assert Ok(#(contacts, _)) = json.parse(body, page_decoder())
  let assert [first, second, third] = contacts

  assert first.first_name == "Alice"
  assert second.first_name == "Bob"
  assert third.first_name == "Charlie"
}

pub fn list_contacts_sort_by_email_desc_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_email("a@example.com")
    |> contact_factory.with_first_name("A")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_email("c@example.com")
    |> contact_factory.with_first_name("C")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_email("b@example.com")
    |> contact_factory.with_first_name("B")
    |> contact_factory.build()
    |> repo.create

  let response =
    simulate.request(
      http.Get,
      "/api/contacts?sort_by=email&sort_direction=desc",
    )
    |> router.handle_request(ctx)

  assert response.status == 200

  let body = simulate.read_body(response)
  let assert Ok(#(contacts, _)) = json.parse(body, page_decoder())
  let assert [first, second, third] = contacts

  assert first.email == "c@example.com"
  assert second.email == "b@example.com"
  assert third.email == "a@example.com"
}

pub fn list_contacts_cursor_first_page_has_next_cursor_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("Alice")
    |> contact_factory.with_email("a@example.com")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("Bob")
    |> contact_factory.with_email("b@example.com")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("Charlie")
    |> contact_factory.with_email("c@example.com")
    |> contact_factory.build()
    |> repo.create

  let response =
    simulate.request(
      http.Get,
      "/api/contacts?sort_by=first_name&sort_direction=asc&limit=2",
    )
    |> router.handle_request(ctx)

  assert response.status == 200

  let body = simulate.read_body(response)
  let assert Ok(#(contacts, next_cursor)) = json.parse(body, page_decoder())
  let assert [first, second] = contacts

  assert first.first_name == "Alice"
  assert second.first_name == "Bob"
  let assert Some(cursor) = next_cursor
  assert cursor.value == "Bob"
  assert cursor.id == second.id
}

pub fn list_contacts_cursor_last_page_has_no_next_cursor_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.build()
    |> repo.create

  let response =
    simulate.request(
      http.Get,
      "/api/contacts?sort_by=first_name&sort_direction=asc&limit=10",
    )
    |> router.handle_request(ctx)

  assert response.status == 200

  let body = simulate.read_body(response)
  let assert Ok(#(contacts, next_cursor)) = json.parse(body, page_decoder())

  assert list.length(contacts) == 2
  assert next_cursor == None
}

pub fn list_contacts_cursor_walks_pages_test() {
  let ctx = test_context.get()
  use ctx <- test_database.with_rollback(ctx)

  let db = context.db_conn(ctx)
  let repo = contacts_repository.new(db)
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("Alice")
    |> contact_factory.with_email("a@example.com")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("Bob")
    |> contact_factory.with_email("b@example.com")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("Charlie")
    |> contact_factory.with_email("c@example.com")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("Dave")
    |> contact_factory.with_email("d@example.com")
    |> contact_factory.build()
    |> repo.create
  let assert Ok(_) =
    contact_factory.new()
    |> contact_factory.with_first_name("Eve")
    |> contact_factory.with_email("e@example.com")
    |> contact_factory.build()
    |> repo.create

  let base_url = "/api/contacts?sort_by=first_name&sort_direction=asc&limit=2"

  let response1 =
    simulate.request(http.Get, base_url)
    |> router.handle_request(ctx)
  let body1 = simulate.read_body(response1)
  let assert Ok(#(page1, next_cursor1)) = json.parse(body1, page_decoder())
  let assert [a, b] = page1
  let assert Some(cursor1) = next_cursor1
  assert a.first_name == "Alice"
  assert b.first_name == "Bob"

  let response2 =
    simulate.request(
      http.Get,
      base_url <> "&cursor=" <> cursor_to_param(cursor1),
    )
    |> router.handle_request(ctx)
  let body2 = simulate.read_body(response2)
  let assert Ok(#(page2, next_cursor2)) = json.parse(body2, page_decoder())
  let assert [c, d] = page2
  let assert Some(cursor2) = next_cursor2
  assert c.first_name == "Charlie"
  assert d.first_name == "Dave"

  let response3 =
    simulate.request(
      http.Get,
      base_url <> "&cursor=" <> cursor_to_param(cursor2),
    )
    |> router.handle_request(ctx)
  let body3 = simulate.read_body(response3)
  let assert Ok(#(page3, next_cursor3)) = json.parse(body3, page_decoder())
  let assert [e] = page3
  assert e.first_name == "Eve"
  assert next_cursor3 == None
}
