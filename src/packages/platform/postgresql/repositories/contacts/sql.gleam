//// This module contains the code to run the sql queries defined in
//// `./src/packages/platform/postgresql/repositories/contacts/sql`.
//// > 🐿️ This module was generated automatically using v4.6.0 of
//// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
////

import gleam/dynamic/decode
import gleam/option.{type Option}
import gleam/time/timestamp.{type Timestamp}
import pog

/// A row you get from running the `count_contacts` query
/// defined in `./src/packages/platform/postgresql/repositories/contacts/sql/count_contacts.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CountContactsRow {
  CountContactsRow(count: Int)
}

/// Count total contacts (for pagination's has_more logic)
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn count_contacts(
  db: pog.Connection,
) -> Result(pog.Returned(CountContactsRow), pog.QueryError) {
  let decoder = {
    use count <- decode.field(0, decode.int)
    decode.success(CountContactsRow(count:))
  }

  "-- Count total contacts (for pagination's has_more logic)
SELECT
  COUNT(*)
FROM
  contacts;
"
  |> pog.query
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `create_contact` query
/// defined in `./src/packages/platform/postgresql/repositories/contacts/sql/create_contact.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type CreateContactRow {
  CreateContactRow(
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

/// Create a new contact
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn create_contact(
  db: pog.Connection,
  arg_1: String,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: String,
  arg_7: PipelineStage,
  arg_8: String,
  arg_9: String,
) -> Result(pog.Returned(CreateContactRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use first_name <- decode.field(1, decode.string)
    use last_name <- decode.field(2, decode.string)
    use email <- decode.field(3, decode.string)
    use phone <- decode.field(4, decode.optional(decode.string))
    use company <- decode.field(5, decode.optional(decode.string))
    use title <- decode.field(6, decode.optional(decode.string))
    use stage <- decode.field(7, pipeline_stage_decoder())
    use profile_picture_url <- decode.field(8, decode.optional(decode.string))
    use notes <- decode.field(9, decode.optional(decode.string))
    use created_at <- decode.field(10, pog.timestamp_decoder())
    use updated_at <- decode.field(11, pog.timestamp_decoder())
    decode.success(CreateContactRow(
      id:,
      first_name:,
      last_name:,
      email:,
      phone:,
      company:,
      title:,
      stage:,
      profile_picture_url:,
      notes:,
      created_at:,
      updated_at:,
    ))
  }

  "-- Create a new contact
INSERT INTO contacts(
  first_name,
  last_name,
  email,
  phone,
  company,
  title,
  stage,
  profile_picture_url,
  notes,
  created_at,
  updated_at
)
VALUES ($1,
$2,
$3,
$4,
$5,
$6,
$7,
$8,
$9,
NOW(),
NOW())
RETURNING id,
first_name,
last_name,
email,
phone,
company,
title,
stage,
profile_picture_url,
notes,
created_at::timestamp,
updated_at::timestamp;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pipeline_stage_encoder(arg_7))
  |> pog.parameter(pog.text(arg_8))
  |> pog.parameter(pog.text(arg_9))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `delete_contact` query
/// defined in `./src/packages/platform/postgresql/repositories/contacts/sql/delete_contact.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type DeleteContactRow {
  DeleteContactRow(id: Int)
}

/// Delete a contact by ID
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn delete_contact(
  db: pog.Connection,
  arg_1: Int,
) -> Result(pog.Returned(DeleteContactRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    decode.success(DeleteContactRow(id:))
  }

  "-- Delete a contact by ID
DELETE FROM contacts
WHERE
  id = $1
RETURNING id;

"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `get_contact` query
/// defined in `./src/packages/platform/postgresql/repositories/contacts/sql/get_contact.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type GetContactRow {
  GetContactRow(
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

/// Get a single contact by ID
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn get_contact(
  db: pog.Connection,
  arg_1: Int,
) -> Result(pog.Returned(GetContactRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use first_name <- decode.field(1, decode.string)
    use last_name <- decode.field(2, decode.string)
    use email <- decode.field(3, decode.string)
    use phone <- decode.field(4, decode.optional(decode.string))
    use company <- decode.field(5, decode.optional(decode.string))
    use title <- decode.field(6, decode.optional(decode.string))
    use stage <- decode.field(7, pipeline_stage_decoder())
    use profile_picture_url <- decode.field(8, decode.optional(decode.string))
    use notes <- decode.field(9, decode.optional(decode.string))
    use created_at <- decode.field(10, pog.timestamp_decoder())
    use updated_at <- decode.field(11, pog.timestamp_decoder())
    decode.success(GetContactRow(
      id:,
      first_name:,
      last_name:,
      email:,
      phone:,
      company:,
      title:,
      stage:,
      profile_picture_url:,
      notes:,
      created_at:,
      updated_at:,
    ))
  }

  "-- Get a single contact by ID
SELECT
  id,
  first_name,
  last_name,
  email,
  phone,
  company,
  title,
  stage,
  profile_picture_url,
  notes,
  created_at::timestamp,
  updated_at::timestamp
FROM
  contacts
WHERE
  id = $1;

"
  |> pog.query
  |> pog.parameter(pog.int(arg_1))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `list_contacts` query
/// defined in `./src/packages/platform/postgresql/repositories/contacts/sql/list_contacts.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type ListContactsRow {
  ListContactsRow(
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

/// Get contacts with filtering and sorting
/// Parameters:
/// $1: stage filter (nullable)
/// $2: company filter (nullable)
/// $3: search term for first_name, last_name, email, company (nullable)
/// $4: email filter (nullable)
/// $5: phone filter (nullable)
/// $6: title filter (nullable)
/// $7: sort column (first_name, last_name, email, company, created_at, updated_at)
/// $8: sort direction (ASC or DESC)
/// $9: limit
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn list_contacts(
  db: pog.Connection,
  arg_1: String,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: String,
  arg_7: String,
  arg_8: String,
  arg_9: Int,
) -> Result(pog.Returned(ListContactsRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use first_name <- decode.field(1, decode.string)
    use last_name <- decode.field(2, decode.string)
    use email <- decode.field(3, decode.string)
    use phone <- decode.field(4, decode.optional(decode.string))
    use company <- decode.field(5, decode.optional(decode.string))
    use title <- decode.field(6, decode.optional(decode.string))
    use stage <- decode.field(7, pipeline_stage_decoder())
    use profile_picture_url <- decode.field(8, decode.optional(decode.string))
    use notes <- decode.field(9, decode.optional(decode.string))
    use created_at <- decode.field(10, pog.timestamp_decoder())
    use updated_at <- decode.field(11, pog.timestamp_decoder())
    decode.success(ListContactsRow(
      id:,
      first_name:,
      last_name:,
      email:,
      phone:,
      company:,
      title:,
      stage:,
      profile_picture_url:,
      notes:,
      created_at:,
      updated_at:,
    ))
  }

  "-- Get contacts with filtering and sorting
-- Parameters:
--   $1: stage filter (nullable)
--   $2: company filter (nullable)
--   $3: search term for first_name, last_name, email, company (nullable)
--   $4: email filter (nullable)
--   $5: phone filter (nullable)
--   $6: title filter (nullable)
--   $7: sort column (first_name, last_name, email, company, created_at, updated_at)
--   $8: sort direction (ASC or DESC)
--   $9: limit
SELECT
  id,
  first_name,
  last_name,
  email,
  phone,
  company,
  title,
  stage,
  profile_picture_url,
  notes,
  created_at::timestamp,
  updated_at::timestamp
FROM contacts
WHERE
  -- Filtering
  (stage::text = $1 OR $1 IS NULL) AND
  (company ILIKE '%' || $2 || '%' OR $2 IS NULL) AND
  (first_name ILIKE '%' || $3 || '%' OR last_name ILIKE '%' || $3 || '%' OR email ILIKE '%' || $3 || '%' OR company ILIKE '%' || $3 || '%' OR $3 IS NULL) AND
  (email ILIKE '%' || $4 || '%' OR $4 IS NULL) AND
  (phone ILIKE '%' || $5 || '%' OR $5 IS NULL) AND
  (title ILIKE '%' || $6 || '%' OR $6 IS NULL) AND
  
  -- Keyset pagination (skip for now since cursor_value can't be NULL)
  TRUE
ORDER BY
  CASE WHEN $7 = 'first_name' AND $8 = 'ASC' THEN first_name END ASC,
  CASE WHEN $7 = 'first_name' AND $8 = 'DESC' THEN first_name END DESC,
  CASE WHEN $7 = 'last_name' AND $8 = 'ASC' THEN last_name END ASC,
  CASE WHEN $7 = 'last_name' AND $8 = 'DESC' THEN last_name END DESC,
  CASE WHEN $7 = 'email' AND $8 = 'ASC' THEN email END ASC,
  CASE WHEN $7 = 'email' AND $8 = 'DESC' THEN email END DESC,
  CASE WHEN $7 = 'company' AND $8 = 'ASC' THEN company END ASC,
  CASE WHEN $7 = 'company' AND $8 = 'DESC' THEN company END DESC,
  CASE WHEN $7 = 'created_at' AND $8 = 'ASC' THEN created_at END ASC,
  CASE WHEN $7 = 'created_at' AND $8 = 'DESC' THEN created_at END DESC,
  CASE WHEN $7 = 'updated_at' AND $8 = 'ASC' THEN updated_at END ASC,
  CASE WHEN $7 = 'updated_at' AND $8 = 'DESC' THEN updated_at END DESC,
  id ASC
LIMIT $9;
"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pog.text(arg_7))
  |> pog.parameter(pog.text(arg_8))
  |> pog.parameter(pog.int(arg_9))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

/// A row you get from running the `update_contact` query
/// defined in `./src/packages/platform/postgresql/repositories/contacts/sql/update_contact.sql`.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type UpdateContactRow {
  UpdateContactRow(
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

/// Update an existing contact
///
/// > 🐿️ This function was generated automatically using v4.6.0 of
/// > the [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub fn update_contact(
  db: pog.Connection,
  arg_1: String,
  arg_2: String,
  arg_3: String,
  arg_4: String,
  arg_5: String,
  arg_6: String,
  arg_7: PipelineStage,
  arg_8: String,
  arg_9: String,
  arg_10: Int,
) -> Result(pog.Returned(UpdateContactRow), pog.QueryError) {
  let decoder = {
    use id <- decode.field(0, decode.int)
    use first_name <- decode.field(1, decode.string)
    use last_name <- decode.field(2, decode.string)
    use email <- decode.field(3, decode.string)
    use phone <- decode.field(4, decode.optional(decode.string))
    use company <- decode.field(5, decode.optional(decode.string))
    use title <- decode.field(6, decode.optional(decode.string))
    use stage <- decode.field(7, pipeline_stage_decoder())
    use profile_picture_url <- decode.field(8, decode.optional(decode.string))
    use notes <- decode.field(9, decode.optional(decode.string))
    use created_at <- decode.field(10, pog.timestamp_decoder())
    use updated_at <- decode.field(11, pog.timestamp_decoder())
    decode.success(UpdateContactRow(
      id:,
      first_name:,
      last_name:,
      email:,
      phone:,
      company:,
      title:,
      stage:,
      profile_picture_url:,
      notes:,
      created_at:,
      updated_at:,
    ))
  }

  "-- Update an existing contact
UPDATE contacts
SET first_name = $1,
last_name = $2,
email = $3,
phone = $4,
company = $5,
title = $6,
stage = $7,
profile_picture_url = $8,
notes = $9,
updated_at = NOW()
WHERE
  id = $10
RETURNING id,
  first_name,
  last_name,
  email,
  phone,
  company,
  title,
  stage,
  profile_picture_url,
  notes,
  created_at::timestamp,
  updated_at::timestamp;

"
  |> pog.query
  |> pog.parameter(pog.text(arg_1))
  |> pog.parameter(pog.text(arg_2))
  |> pog.parameter(pog.text(arg_3))
  |> pog.parameter(pog.text(arg_4))
  |> pog.parameter(pog.text(arg_5))
  |> pog.parameter(pog.text(arg_6))
  |> pog.parameter(pipeline_stage_encoder(arg_7))
  |> pog.parameter(pog.text(arg_8))
  |> pog.parameter(pog.text(arg_9))
  |> pog.parameter(pog.int(arg_10))
  |> pog.returning(decoder)
  |> pog.execute(db)
}

// --- Enums -------------------------------------------------------------------

/// Corresponds to the Postgres `pipeline_stage` enum.
///
/// > 🐿️ This type definition was generated automatically using v4.6.0 of the
/// > [squirrel package](https://github.com/giacomocavalieri/squirrel).
///
pub type PipelineStage {
  Customer
  Opportunity
  Contact
  Lead
}

fn pipeline_stage_decoder() -> decode.Decoder(PipelineStage) {
  use pipeline_stage <- decode.then(decode.string)
  case pipeline_stage {
    "customer" -> decode.success(Customer)
    "opportunity" -> decode.success(Opportunity)
    "contact" -> decode.success(Contact)
    "lead" -> decode.success(Lead)
    _ -> decode.failure(Customer, "PipelineStage")
  }
}

fn pipeline_stage_encoder(pipeline_stage) -> pog.Value {
  case pipeline_stage {
    Customer -> "customer"
    Opportunity -> "opportunity"
    Contact -> "contact"
    Lead -> "lead"
  }
  |> pog.text
}
