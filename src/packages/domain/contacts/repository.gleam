import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import packages/platform/postgresql/repositories/contacts/sql.{type PipelineStage}

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
    cursor_value: Option(String),
    cursor_id: Option(Int),
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

pub type Error {
  DatabaseError(String)
  NotFound(Int)
}

// --- Repository Interface (Ports) ---

pub type Repository {
  Repository(
    get: fn(Int) -> Result(Contact, Error),
    list: fn(ListParams) -> Result(List(Contact), Error),
    create: fn(Contact) -> Result(Contact, Error),
    update: fn(Contact) -> Result(Contact, Error),
    delete: fn(Int) -> Result(Nil, Error),
  )
}
