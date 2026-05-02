import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}
import gleam/time/calendar
import gleam/time/timestamp.{type Timestamp}

pub type PipelineStage {
  CustomerStage
  OpportunityStage
  ContactStage
  LeadStage
}

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

// --- JSON ---

pub fn to_json(contact: Contact) -> json.Json {
  json.object([
    #("id", json.int(contact.id)),
    #("first_name", json.string(contact.first_name)),
    #("last_name", json.string(contact.last_name)),
    #("email", json.string(contact.email)),
    #("phone", json.nullable(contact.phone, json.string)),
    #("company", json.nullable(contact.company, json.string)),
    #("title", json.nullable(contact.title, json.string)),
    #("stage", json.string(stage_to_string(contact.stage))),
    #(
      "profile_picture_url",
      json.nullable(contact.profile_picture_url, json.string),
    ),
    #("notes", json.nullable(contact.notes, json.string)),
    #(
      "created_at",
      json.string(timestamp.to_rfc3339(contact.created_at, calendar.utc_offset)),
    ),
    #(
      "updated_at",
      json.string(timestamp.to_rfc3339(contact.updated_at, calendar.utc_offset)),
    ),
  ])
}

// --- Decoder ---

pub fn decoder() -> decode.Decoder(Contact) {
  use id <- decode.field("id", decode.int)
  use first_name <- decode.field("first_name", decode.string)
  use last_name <- decode.field("last_name", decode.string)
  use email <- decode.field("email", decode.string)
  use phone <- decode.field("phone", decode.optional(decode.string))
  use company <- decode.field("company", decode.optional(decode.string))
  use title <- decode.field("title", decode.optional(decode.string))
  use s <- decode.field("stage", stage_decoder())
  use profile_picture_url <- decode.field(
    "profile_picture_url",
    decode.optional(decode.string),
  )
  use notes <- decode.field("notes", decode.optional(decode.string))
  use created_at <- decode.field("created_at", timestamp_decoder())
  use updated_at <- decode.field("updated_at", timestamp_decoder())
  decode.success(Contact(
    id:,
    first_name:,
    last_name:,
    email:,
    phone:,
    company:,
    title:,
    stage: s,
    profile_picture_url:,
    notes:,
    created_at:,
    updated_at:,
  ))
}

fn stage_to_string(s: PipelineStage) -> String {
  case s {
    CustomerStage -> "Customer"
    OpportunityStage -> "Opportunity"
    ContactStage -> "Contact"
    LeadStage -> "Lead"
  }
}

fn stage_decoder() -> decode.Decoder(PipelineStage) {
  use s <- decode.then(decode.string)
  case s {
    "Customer" -> decode.success(CustomerStage)
    "Opportunity" -> decode.success(OpportunityStage)
    "Contact" -> decode.success(ContactStage)
    "Lead" -> decode.success(LeadStage)
    _ -> decode.failure(LeadStage, "PipelineStage")
  }
}

fn timestamp_decoder() -> decode.Decoder(Timestamp) {
  use s <- decode.then(decode.string)
  case timestamp.parse_rfc3339(s) {
    Ok(ts) -> decode.success(ts)
    Error(_) -> decode.failure(timestamp.from_unix_seconds(0), "Timestamp")
  }
}
