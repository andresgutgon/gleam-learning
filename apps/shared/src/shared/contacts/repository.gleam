import gleam/option.{type Option}
import gleam/time/calendar
import gleam/time/timestamp
import shared/contacts/contact.{type Contact, type ContactInput, type PipelineStage}
import shared/error.{type DatabaseError}
import shared/pagination.{type Cursor, type Page, Cursor}

pub type Repository {
  Repository(
    get: fn(Int) -> Result(Contact, DatabaseError),
    list: fn(ListParams) -> Result(Page(Contact), DatabaseError),
    create: fn(ContactInput) -> Result(Contact, DatabaseError),
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
  SortByName
  SortByEmail
  SortByCompany
  SortByCreatedAt
  SortByUpdatedAt
}

pub type SortDirection {
  Ascending
  Descending
}

// --- String conversions ---

pub fn sort_field_to_string(sort_by: SortField) -> String {
  case sort_by {
    SortByName -> "name"
    SortByEmail -> "email"
    SortByCompany -> "company"
    SortByCreatedAt -> "created_at"
    SortByUpdatedAt -> "updated_at"
  }
}

pub fn sort_field_from_string(s: String) -> SortField {
  case s {
    "name" -> SortByName
    "email" -> SortByEmail
    "company" -> SortByCompany
    "updated_at" -> SortByUpdatedAt
    _ -> SortByCreatedAt
  }
}

pub fn sort_direction_to_string(direction: SortDirection) -> String {
  case direction {
    Ascending -> "asc"
    Descending -> "desc"
  }
}

pub fn sort_direction_from_string(s: String) -> SortDirection {
  case s {
    "asc" -> Ascending
    _ -> Descending
  }
}

// --- Cursor helpers ---

/// Build a cursor from a contact for the given sort field. Use this on the
/// last item of a page to construct the cursor for the next page.
pub fn cursor_from_contact(contact: Contact, sort_by: SortField) -> Cursor {
  Cursor(value: cursor_value_for(contact, sort_by), id: contact.id)
}

fn cursor_value_for(contact: Contact, sort_by: SortField) -> String {
  case sort_by {
    SortByName -> contact.first_name <> " " <> contact.last_name
    SortByEmail -> contact.email
    SortByCompany -> option.unwrap(contact.company, "")
    SortByCreatedAt ->
      timestamp.to_rfc3339(contact.created_at, calendar.utc_offset)
    SortByUpdatedAt ->
      timestamp.to_rfc3339(contact.updated_at, calendar.utc_offset)
  }
}
