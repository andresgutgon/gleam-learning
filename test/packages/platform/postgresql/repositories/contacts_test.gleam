//// Unit tests for PostgreSQL contacts repository
//// These tests use transaction-based rollback for isolation

import factories/contact as contact_factory
import gleam/list
import gleam/option.{None, Some}
import gleeunit
import gleeunit/should
import packages/domain/contacts/repository.{
  Ascending, Descending, ListParams, SortByCompany, SortByCreatedAt, SortByEmail,
  SortByFirstName,
}
import packages/platform/postgresql/repositories/contacts/repository as pg_repo
import packages/platform/postgresql/repositories/contacts/sql.{
  Customer, Lead, Opportunity,
}
import support/db

pub fn main() {
  gleeunit.main()
}

// --- Setup helpers ---

fn with_test_db(test_fn: fn(repository.Repository) -> a) -> a {
  let assert Ok(db) = db.test_connection()
  db.with_rollback(db, fn(db) {
    let repo = pg_repo.new(db)
    test_fn(repo)
  })
}

// --- Get contact tests ---

pub fn get_contact_success_test() {
  with_test_db(fn(repo) {
    // Create a contact
    let contact = contact_factory.new() |> contact_factory.build()
    let assert Ok(created) = repo.create(contact)

    // Get it back
    let assert Ok(retrieved) = repo.get(created.id)

    // Verify
    retrieved.id |> should.equal(created.id)
    retrieved.email |> should.equal(created.email)
    retrieved.first_name |> should.equal(created.first_name)
    retrieved.last_name |> should.equal(created.last_name)
  })
}

pub fn get_contact_not_found_test() {
  with_test_db(fn(repo) {
    let result = repo.get(99_999)
    result |> should.be_error()

    case result {
      Error(repository.NotFound(id)) -> id |> should.equal(99_999)
      _ -> panic as "Expected NotFound error"
    }
  })
}

// --- Create contact tests ---

pub fn create_contact_success_test() {
  with_test_db(fn(repo) {
    let contact =
      contact_factory.new()
      |> contact_factory.with_email("test@example.com")
      |> contact_factory.with_first_name("Jane")
      |> contact_factory.with_last_name("Smith")
      |> contact_factory.with_company("Acme Corp")
      |> contact_factory.with_stage(Opportunity)
      |> contact_factory.build()

    let assert Ok(created) = repo.create(contact)

    // Verify returned contact
    created.email |> should.equal("test@example.com")
    created.first_name |> should.equal("Jane")
    created.last_name |> should.equal("Smith")
    created.company |> should.equal(Some("Acme Corp"))
    created.stage |> should.equal(Opportunity)
    created.id |> should.not_equal(0)
  })
}

pub fn create_contact_with_all_fields_test() {
  with_test_db(fn(repo) {
    let contact =
      contact_factory.new()
      |> contact_factory.with_email("full@example.com")
      |> contact_factory.with_phone("+1234567890")
      |> contact_factory.with_title("CEO")
      |> contact_factory.with_profile_picture_url("https://example.com/pic.jpg")
      |> contact_factory.with_notes("VIP customer")
      |> contact_factory.with_stage(Customer)
      |> contact_factory.build()

    let assert Ok(created) = repo.create(contact)

    created.phone |> should.equal(Some("+1234567890"))
    created.title |> should.equal(Some("CEO"))
    created.profile_picture_url
    |> should.equal(Some("https://example.com/pic.jpg"))
    created.notes |> should.equal(Some("VIP customer"))
    created.stage |> should.equal(Customer)
  })
}

// --- Update contact tests ---

pub fn update_contact_success_test() {
  with_test_db(fn(repo) {
    // Create
    let contact = contact_factory.new() |> contact_factory.build()
    let assert Ok(created) = repo.create(contact)

    // Update
    let updated_contact =
      repository.Contact(
        ..created,
        first_name: "Updated",
        company: Some("New Company"),
        stage: Customer,
      )
    let assert Ok(updated) = repo.update(updated_contact)

    // Verify
    updated.first_name |> should.equal("Updated")
    updated.company |> should.equal(Some("New Company"))
    updated.stage |> should.equal(Customer)
    updated.id |> should.equal(created.id)
  })
}

pub fn update_contact_not_found_test() {
  with_test_db(fn(repo) {
    let contact =
      contact_factory.new()
      |> contact_factory.build()
      |> fn(c) { repository.Contact(..c, id: 99_999) }

    let result = repo.update(contact)
    result |> should.be_error()

    case result {
      Error(repository.NotFound(id)) -> id |> should.equal(99_999)
      _ -> panic as "Expected NotFound error"
    }
  })
}

// --- Delete contact tests ---

pub fn delete_contact_success_test() {
  with_test_db(fn(repo) {
    // Create
    let contact = contact_factory.new() |> contact_factory.build()
    let assert Ok(created) = repo.create(contact)

    // Delete
    let assert Ok(Nil) = repo.delete(created.id)

    // Verify it's gone
    let result = repo.get(created.id)
    result |> should.be_error()
  })
}

pub fn delete_contact_not_found_test() {
  with_test_db(fn(repo) {
    let result = repo.delete(99_999)
    result |> should.be_error()

    case result {
      Error(repository.NotFound(id)) -> id |> should.equal(99_999)
      _ -> panic as "Expected NotFound error"
    }
  })
}

// --- List contacts tests ---

pub fn list_contacts_empty_test() {
  with_test_db(fn(repo) {
    let params =
      ListParams(
        stage: None,
        company: None,
        search: None,
        email: None,
        phone: None,
        title: None,
        sort_by: SortByCreatedAt,
        sort_direction: Descending,
        cursor_value: None,
        cursor_id: None,
        limit: 10,
      )

    let assert Ok(contacts) = repo.list(params)
    contacts |> should.equal([])
  })
}

pub fn list_contacts_returns_all_test() {
  with_test_db(fn(repo) {
    // Create 3 contacts
    let assert Ok(_) =
      contact_factory.new_with_sequence(1)
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new_with_sequence(2)
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new_with_sequence(3)
      |> contact_factory.build()
      |> repo.create()

    let params =
      ListParams(
        stage: None,
        company: None,
        search: None,
        email: None,
        phone: None,
        title: None,
        sort_by: SortByCreatedAt,
        sort_direction: Descending,
        cursor_value: None,
        cursor_id: None,
        limit: 10,
      )

    let assert Ok(contacts) = repo.list(params)
    list.length(contacts) |> should.equal(3)
  })
}

pub fn list_contacts_filter_by_stage_test() {
  with_test_db(fn(repo) {
    // Create contacts with different stages
    let assert Ok(_) =
      contact_factory.new_with_sequence(1)
      |> contact_factory.with_stage(Lead)
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new_with_sequence(2)
      |> contact_factory.with_stage(Customer)
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new_with_sequence(3)
      |> contact_factory.with_stage(Lead)
      |> contact_factory.build()
      |> repo.create()

    let params =
      ListParams(
        stage: Some(Lead),
        company: None,
        search: None,
        email: None,
        phone: None,
        title: None,
        sort_by: SortByCreatedAt,
        sort_direction: Ascending,
        cursor_value: None,
        cursor_id: None,
        limit: 10,
      )

    let assert Ok(contacts) = repo.list(params)
    list.length(contacts) |> should.equal(2)
    list.all(contacts, fn(c) { c.stage == Lead }) |> should.be_true()
  })
}

pub fn list_contacts_filter_by_company_test() {
  with_test_db(fn(repo) {
    // Create contacts with different companies
    let assert Ok(_) =
      contact_factory.new_with_sequence(1)
      |> contact_factory.with_company("Acme Corp")
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new_with_sequence(2)
      |> contact_factory.with_company("Tech Inc")
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new_with_sequence(3)
      |> contact_factory.with_company("Acme Corp")
      |> contact_factory.build()
      |> repo.create()

    let params =
      ListParams(
        stage: None,
        company: Some("Acme"),
        search: None,
        email: None,
        phone: None,
        title: None,
        sort_by: SortByCompany,
        sort_direction: Ascending,
        cursor_value: None,
        cursor_id: None,
        limit: 10,
      )

    let assert Ok(contacts) = repo.list(params)
    list.length(contacts) |> should.equal(2)
  })
}

pub fn list_contacts_filter_by_search_test() {
  with_test_db(fn(repo) {
    // Create contacts with searchable fields
    let assert Ok(_) =
      contact_factory.new_with_sequence(1)
      |> contact_factory.with_first_name("John")
      |> contact_factory.with_last_name("Smith")
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new_with_sequence(2)
      |> contact_factory.with_first_name("Jane")
      |> contact_factory.with_last_name("Doe")
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new_with_sequence(3)
      |> contact_factory.with_first_name("Bob")
      |> contact_factory.with_last_name("Johnson")
      |> contact_factory.build()
      |> repo.create()

    let params =
      ListParams(
        stage: None,
        company: None,
        search: Some("John"),
        email: None,
        phone: None,
        title: None,
        sort_by: SortByFirstName,
        sort_direction: Ascending,
        cursor_value: None,
        cursor_id: None,
        limit: 10,
      )

    let assert Ok(contacts) = repo.list(params)
    list.length(contacts) |> should.equal(2)
  })
}

pub fn list_contacts_sort_by_first_name_asc_test() {
  with_test_db(fn(repo) {
    // Create contacts
    let assert Ok(_) =
      contact_factory.new()
      |> contact_factory.with_first_name("Charlie")
      |> contact_factory.with_email("c@example.com")
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new()
      |> contact_factory.with_first_name("Alice")
      |> contact_factory.with_email("a@example.com")
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new()
      |> contact_factory.with_first_name("Bob")
      |> contact_factory.with_email("b@example.com")
      |> contact_factory.build()
      |> repo.create()

    let params =
      ListParams(
        stage: None,
        company: None,
        search: None,
        email: None,
        phone: None,
        title: None,
        sort_by: SortByFirstName,
        sort_direction: Ascending,
        cursor_value: None,
        cursor_id: None,
        limit: 10,
      )

    let assert Ok(contacts) = repo.list(params)
    let assert [first, second, third] = contacts

    first.first_name |> should.equal("Alice")
    second.first_name |> should.equal("Bob")
    third.first_name |> should.equal("Charlie")
  })
}

pub fn list_contacts_sort_by_email_desc_test() {
  with_test_db(fn(repo) {
    // Create contacts
    let assert Ok(_) =
      contact_factory.new()
      |> contact_factory.with_email("a@example.com")
      |> contact_factory.with_first_name("A")
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new()
      |> contact_factory.with_email("c@example.com")
      |> contact_factory.with_first_name("C")
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new()
      |> contact_factory.with_email("b@example.com")
      |> contact_factory.with_first_name("B")
      |> contact_factory.build()
      |> repo.create()

    let params =
      ListParams(
        stage: None,
        company: None,
        search: None,
        email: None,
        phone: None,
        title: None,
        sort_by: SortByEmail,
        sort_direction: Descending,
        cursor_value: None,
        cursor_id: None,
        limit: 10,
      )

    let assert Ok(contacts) = repo.list(params)
    let assert [first, second, third] = contacts

    first.email |> should.equal("c@example.com")
    second.email |> should.equal("b@example.com")
    third.email |> should.equal("a@example.com")
  })
}

pub fn list_contacts_limit_test() {
  with_test_db(fn(repo) {
    // Create 5 contacts
    let assert Ok(_) =
      contact_factory.new_with_sequence(1)
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new_with_sequence(2)
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new_with_sequence(3)
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new_with_sequence(4)
      |> contact_factory.build()
      |> repo.create()
    let assert Ok(_) =
      contact_factory.new_with_sequence(5)
      |> contact_factory.build()
      |> repo.create()

    let params =
      ListParams(
        stage: None,
        company: None,
        search: None,
        email: None,
        phone: None,
        title: None,
        sort_by: SortByCreatedAt,
        sort_direction: Ascending,
        cursor_value: None,
        cursor_id: None,
        limit: 3,
      )

    let assert Ok(contacts) = repo.list(params)
    list.length(contacts) |> should.equal(3)
  })
}
// TODO: Add cursor pagination tests after implementing cursor-based pagination
