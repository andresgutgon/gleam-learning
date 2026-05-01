import gleam/option.{type Option}
import gleam/time/calendar
import gleam/time/timestamp.{type Timestamp}
import packages/platform/postgresql/repositories/contacts/sql.{
  type PipelineStage,
}

// --- Domain Types ---

pub type Contact {
  Contact(
    id: Int,
    first_name: String,
    last_name: String,
    email: String,
    phone: Option(String),
    company: Option(String),
    title: Option(String),
    stage: PipelineStage,
    profile_picture_url: Option(String),
    notes: Option(String),
    created_at: Timestamp,
    updated_at: Timestamp,
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

/// Opaque-ish keyset cursor. `value` is the text-encoded sort column value
/// at the boundary row; timestamps are encoded as RFC3339. `id` is the row's
/// primary key, used as the tiebreaker.
pub type Cursor {
  Cursor(value: String, id: Int)
}

/// Result of a paginated list query. `next_cursor` is `Some` when there is
/// at least one more page after the returned `contacts`, and `None` on the
/// last page.
pub type ListResult {
  ListResult(contacts: List(Contact), next_cursor: Option(Cursor))
}

pub type Error {
  DatabaseError(String)
  NotFound(Int)
}

// --- Repository Interface (Ports) ---

pub type Repository {
  Repository(
    get: fn(Int) -> Result(Contact, Error),
    list: fn(ListParams) -> Result(ListResult, Error),
    create: fn(Contact) -> Result(Contact, Error),
    update: fn(Contact) -> Result(Contact, Error),
    delete: fn(Int) -> Result(Nil, Error),
  )
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
