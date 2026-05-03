import gleam/option.{type Option}
import gleam/time/calendar
import gleam/time/timestamp
import shared/contacts/contact.{type Contact, type PipelineStage}
import shared/error.{type DatabaseError}
import shared/pagination.{type Cursor, type Page, Cursor}

pub type Repository {
  Repository(
    get: fn(Int) -> Result(Contact, DatabaseError),
    list: fn(ListParams) -> Result(Page(Contact), DatabaseError),
    create: fn(Contact) -> Result(Contact, DatabaseError),
    update: fn(Contact) -> Result(Contact, DatabaseError),
    delete: fn(Int) -> Result(Nil, DatabaseError),
  )
}

pub type ListParams {
  ListParams(
    // Filtering
    stage: Option(PipelineStage),
    company: Option(String),
    search: Option(String),
    email: Option(String),
    phone: Option(String),
    title: Option(String),
    // Sorting
    sort_by: SortField,
    sort_direction: SortDirection,
    // Pagination
    cursor: Option(Cursor),
    limit: Int,
  )
}

pub type SortField {
  SortByFirstName
  SortByLastName
  SortByEmail
  SortByCompany
  SortByCreatedAt
  SortByUpdatedAt
}

pub type SortDirection {
  Ascending
  Descending
}

// --- Cursor helpers ---

/// Build a cursor from a contact for the given sort field. Use this on the
/// last item of a page to construct the cursor for the next page.
pub fn cursor_from_contact(contact: Contact, sort_by: SortField) -> Cursor {
  Cursor(value: cursor_value_for(contact, sort_by), id: contact.id)
}

fn cursor_value_for(contact: Contact, sort_by: SortField) -> String {
  case sort_by {
    SortByFirstName -> contact.first_name
    SortByLastName -> contact.last_name
    SortByEmail -> contact.email
    SortByCompany -> option.unwrap(contact.company, "")
    SortByCreatedAt ->
      timestamp.to_rfc3339(contact.created_at, calendar.utc_offset)
    SortByUpdatedAt ->
      timestamp.to_rfc3339(contact.updated_at, calendar.utc_offset)
  }
}
