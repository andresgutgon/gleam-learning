import gleam/dict.{type Dict}
import gleam/int
import gleam/list
import gleam/option.{None}
import packages/domain/contacts/repository.{
  type Contact, type Error, type ListParams, type ListResult, Contact,
  ListResult, NotFound,
}

pub type MockContactsRepository {
  MockContactsRepository(contacts: Dict(Int, Contact))
}

// --- Ports Implementation ---

pub fn get(repo: MockContactsRepository, id: Int) -> Result(Contact, Error) {
  case dict.get(repo.contacts, id) {
    Ok(contact) -> Ok(contact)
    Error(Nil) -> Error(NotFound(id))
  }
}

pub fn list(
  repo: MockContactsRepository,
  _params: ListParams,
) -> Result(ListResult, Error) {
  // In-memory filtering, sorting, and cursor pagination would go here.
  // For now this returns the raw set with no next cursor — the PostgreSQL
  // adapter is the real implementation.
  Ok(ListResult(contacts: dict.values(repo.contacts), next_cursor: None))
}

pub fn create(
  repo: MockContactsRepository,
  contact: Contact,
) -> Result(Contact, Error) {
  // Generate a simple ID for mock data
  let next_id = case dict.keys(repo.contacts) |> list.reduce(int.max) {
    Ok(max_id) -> max_id + 1
    Error(Nil) -> 1
  }

  // Explicitly construct the new contact with the updated ID
  let new_contact =
    Contact(
      id: next_id,
      first_name: contact.first_name,
      last_name: contact.last_name,
      email: contact.email,
      phone: contact.phone,
      company: contact.company,
      title: contact.title,
      stage: contact.stage,
      profile_picture_url: contact.profile_picture_url,
      notes: contact.notes,
      created_at: contact.created_at,
      updated_at: contact.updated_at,
    )

  // Insert into the dict (dicts are immutable, insert returns a new dict)
  let _new_contacts = dict.insert(repo.contacts, next_id, new_contact)

  Ok(new_contact)
}

pub fn update(
  repo: MockContactsRepository,
  contact: Contact,
) -> Result(Contact, Error) {
  case dict.get(repo.contacts, contact.id) {
    Ok(_) -> {
      let _new_contacts = dict.insert(repo.contacts, contact.id, contact)
      Ok(contact)
    }
    Error(Nil) -> Error(NotFound(contact.id))
  }
}

pub fn delete(repo: MockContactsRepository, id: Int) -> Result(Nil, Error) {
  case dict.get(repo.contacts, id) {
    Ok(_) -> {
      let _new_contacts = dict.delete(repo.contacts, id)
      Ok(Nil)
    }
    Error(Nil) -> Error(NotFound(id))
  }
}
