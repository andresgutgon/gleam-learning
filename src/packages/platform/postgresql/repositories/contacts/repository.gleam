import gleam/list
import gleam/option
import gleam/result
import packages/domain/contacts/repository.{
  type Contact, type Error, type ListParams, type Repository, type SortDirection,
  type SortField, Ascending, Contact, DatabaseError, Descending, NotFound,
  Repository, SortByCompany, SortByCreatedAt, SortByEmail, SortByFirstName,
  SortByLastName, SortByUpdatedAt,
}
import packages/platform/postgresql/repositories/contacts/sql.{type PipelineStage}
import pog

pub type PogContactsRepository {
  PogContactsRepository(db: pog.Connection)
}

// Create a Repository interface from PogContactsRepository
pub fn new(db: pog.Connection) -> Repository {
  let repo = PogContactsRepository(db: db)
  Repository(
    get: fn(id) { get(repo, id) },
    list: fn(params) { list(repo, params) },
    create: fn(contact) { create(repo, contact) },
    update: fn(contact) { update(repo, contact) },
    delete: fn(id) { delete(repo, id) },
  )
}

// --- Ports Implementation ---

pub fn get(repo: PogContactsRepository, id: Int) -> Result(Contact, Error) {
  use returned <- result.try(
    sql.get_contact(repo.db, id)
    |> result.map_error(pog_error_to_repo_error),
  )

  case returned.rows {
    [contact, ..] -> Ok(get_contact_row_to_contact(contact))
    [] -> Error(NotFound(id))
  }
}

pub fn list(
  repo: PogContactsRepository,
  params: ListParams,
) -> Result(List(Contact), Error) {
  sql.list_contacts(
    repo.db,
    option.map(params.stage, pipeline_stage_to_sql) |> option.unwrap(""),
    option.unwrap(params.company, ""),
    option.unwrap(params.search, ""),
    option.unwrap(params.email, ""),
    option.unwrap(params.phone, ""),
    option.unwrap(params.title, ""),
    sort_field_to_sql(params.sort_by),
    sort_direction_to_sql(params.sort_direction),
    params.limit,
  )
  |> result.map(fn(returned) {
    returned.rows
    |> list.map(list_contacts_row_to_contact)
  })
  |> result.map_error(pog_error_to_repo_error)
}

pub fn create(
  repo: PogContactsRepository,
  contact: Contact,
) -> Result(Contact, Error) {
  use returned <- result.try(
    sql.create_contact(
      repo.db,
      contact.first_name,
      contact.last_name,
      contact.email,
      option.unwrap(contact.phone, ""),
      option.unwrap(contact.company, ""),
      option.unwrap(contact.title, ""),
      contact.stage,
      option.unwrap(contact.profile_picture_url, ""),
      option.unwrap(contact.notes, ""),
    )
    |> result.map_error(pog_error_to_repo_error),
  )

  case returned.rows {
    [created, ..] -> Ok(create_contact_row_to_contact(created))
    [] -> Error(DatabaseError("Failed to create contact"))
  }
}

pub fn update(
  repo: PogContactsRepository,
  contact: Contact,
) -> Result(Contact, Error) {
  use returned <- result.try(
    sql.update_contact(
      repo.db,
      contact.first_name,
      contact.last_name,
      contact.email,
      option.unwrap(contact.phone, ""),
      option.unwrap(contact.company, ""),
      option.unwrap(contact.title, ""),
      contact.stage,
      option.unwrap(contact.profile_picture_url, ""),
      option.unwrap(contact.notes, ""),
      contact.id,
    )
    |> result.map_error(pog_error_to_repo_error),
  )

  case returned.rows {
    [updated, ..] -> Ok(update_contact_row_to_contact(updated))
    [] -> Error(NotFound(contact.id))
  }
}

pub fn delete(repo: PogContactsRepository, id: Int) -> Result(Nil, Error) {
  use returned <- result.try(
    sql.delete_contact(repo.db, id)
    |> result.map_error(pog_error_to_repo_error),
  )

  case returned.rows {
    [_deleted, ..] -> Ok(Nil)
    [] -> Error(NotFound(id))
  }
}

// --- Converters ---

fn get_contact_row_to_contact(row: sql.GetContactRow) -> Contact {
  Contact(
    id: row.id,
    first_name: row.first_name,
    last_name: row.last_name,
    email: row.email,
    phone: row.phone,
    company: row.company,
    title: row.title,
    stage: row.stage,
    profile_picture_url: row.profile_picture_url,
    notes: row.notes,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

fn list_contacts_row_to_contact(row: sql.ListContactsRow) -> Contact {
  Contact(
    id: row.id,
    first_name: row.first_name,
    last_name: row.last_name,
    email: row.email,
    phone: row.phone,
    company: row.company,
    title: row.title,
    stage: row.stage,
    profile_picture_url: row.profile_picture_url,
    notes: row.notes,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

fn create_contact_row_to_contact(row: sql.CreateContactRow) -> Contact {
  Contact(
    id: row.id,
    first_name: row.first_name,
    last_name: row.last_name,
    email: row.email,
    phone: row.phone,
    company: row.company,
    title: row.title,
    stage: row.stage,
    profile_picture_url: row.profile_picture_url,
    notes: row.notes,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

fn update_contact_row_to_contact(row: sql.UpdateContactRow) -> Contact {
  Contact(
    id: row.id,
    first_name: row.first_name,
    last_name: row.last_name,
    email: row.email,
    phone: row.phone,
    company: row.company,
    title: row.title,
    stage: row.stage,
    profile_picture_url: row.profile_picture_url,
    notes: row.notes,
    created_at: row.created_at,
    updated_at: row.updated_at,
  )
}

fn pipeline_stage_to_sql(stage: PipelineStage) -> String {
  case stage {
    sql.Customer -> "customer"
    sql.Opportunity -> "opportunity"
    sql.Contact -> "contact"
    sql.Lead -> "lead"
  }
}

fn sort_field_to_sql(field: SortField) -> String {
  case field {
    SortByFirstName -> "first_name"
    SortByLastName -> "last_name"
    SortByEmail -> "email"
    SortByCompany -> "company"
    SortByCreatedAt -> "created_at"
    SortByUpdatedAt -> "updated_at"
  }
}

fn sort_direction_to_sql(direction: SortDirection) -> String {
  case direction {
    Ascending -> "ASC"
    Descending -> "DESC"
  }
}

// --- Error Handling ---

fn pog_error_to_repo_error(err: pog.QueryError) -> Error {
  case err {
    pog.ConstraintViolated(message, _, _) -> DatabaseError(message)
    pog.PostgresqlError(_, _, message) -> DatabaseError(message)
    pog.UnexpectedArgumentCount(_, _) ->
      DatabaseError("Unexpected argument count")
    pog.UnexpectedArgumentType(_, _) ->
      DatabaseError("Unexpected argument type")
    pog.UnexpectedResultType(_) -> DatabaseError("Unexpected result type")
    pog.QueryTimeout -> DatabaseError("Query timeout")
    pog.ConnectionUnavailable -> DatabaseError("Connection unavailable")
  }
}
