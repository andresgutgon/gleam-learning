import app/error.{type DatabaseError, RecordNotFound}
import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None}
import shared/contacts/contact.{type Contact, Contact}
import shared/contacts/repository.{type ListParams}
import shared/pagination.{type Page, Page}

pub type MockContactsRepository {
  MockContactsRepository(contacts: Dict(Int, Contact))
}

// --- Ports Implementation ---

pub fn get(repo: MockContactsRepository, id: Int) -> Result(Contact, DatabaseError) {
  case dict.get(repo.contacts, id) {
    Ok(contact) -> Ok(contact)
    Error(Nil) -> Error(RecordNotFound)
  }
}

pub fn list(
  repo: MockContactsRepository,
  _params: ListParams,
) -> Result(Page(Contact), DatabaseError) {
  // In-memory filtering, sorting, and cursor pagination would go here.
  // For now this returns the raw set with no next cursor — the PostgreSQL
  // adapter is the real implementation.
  Ok(Page(data: dict.values(repo.contacts), next_cursor: None))
}

pub fn create(
  repo: MockContactsRepository,
  contact: Contact,
) -> Result(Contact, DatabaseError) {
  let next_id = case dict.keys(repo.contacts) |> list.reduce(int.max) {
    Ok(max_id) -> max_id + 1
    Error(Nil) -> 1
  }

  let new_contact =
    Contact(
      ..contact,
      id: next_id,
    )

  let _new_contacts = dict.insert(repo.contacts, next_id, new_contact)

  Ok(new_contact)
}

pub fn update(
  repo: MockContactsRepository,
  contact: Contact,
) -> Result(Contact, DatabaseError) {
  case dict.get(repo.contacts, contact.id) {
    Ok(_) -> {
      let _new_contacts = dict.insert(repo.contacts, contact.id, contact)
      Ok(contact)
    }
    Error(Nil) -> Error(RecordNotFound)
  }
}

pub fn delete(repo: MockContactsRepository, id: Int) -> Result(Nil, DatabaseError) {
  case dict.get(repo.contacts, id) {
    Ok(_) -> {
      let _new_contacts = dict.delete(repo.contacts, id)
      Ok(Nil)
    }
    Error(Nil) -> Error(RecordNotFound)
  }
}
