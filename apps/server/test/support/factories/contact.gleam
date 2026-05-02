import gleam/option.{type Option, None, Some}
import gleam/time/timestamp
import shared/contacts/contact.{type Contact, Contact, type PipelineStage, LeadStage}

pub type ContactFactory {
  ContactFactory(
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
  )
}

/// Create a new contact factory with sensible defaults
pub fn new() -> ContactFactory {
  ContactFactory(
    id: 0,
    first_name: "John",
    last_name: "Doe",
    email: "john.doe@example.com",
    phone: None,
    company: None,
    title: None,
    stage: LeadStage,
    profile_picture_url: None,
    notes: None,
  )
}

/// Create a contact factory with a sequence number for unique data
pub fn new_with_sequence(seq: Int) -> ContactFactory {
  let seq_str = int_to_string(seq)
  ContactFactory(
    id: 0,
    first_name: "User" <> seq_str,
    last_name: "Test" <> seq_str,
    email: "user" <> seq_str <> "@example.com",
    phone: None,
    company: None,
    title: None,
    stage: LeadStage,
    profile_picture_url: None,
    notes: None,
  )
}

/// Set the first name
pub fn with_first_name(
  factory: ContactFactory,
  first_name: String,
) -> ContactFactory {
  ContactFactory(..factory, first_name: first_name)
}

/// Set the last name
pub fn with_last_name(
  factory: ContactFactory,
  last_name: String,
) -> ContactFactory {
  ContactFactory(..factory, last_name: last_name)
}

/// Set the email
pub fn with_email(factory: ContactFactory, email: String) -> ContactFactory {
  ContactFactory(..factory, email: email)
}

/// Set the phone
pub fn with_phone(factory: ContactFactory, phone: String) -> ContactFactory {
  ContactFactory(..factory, phone: Some(phone))
}

/// Set the company
pub fn with_company(
  factory: ContactFactory,
  company: String,
) -> ContactFactory {
  ContactFactory(..factory, company: Some(company))
}

/// Set the title
pub fn with_title(factory: ContactFactory, title: String) -> ContactFactory {
  ContactFactory(..factory, title: Some(title))
}

/// Set the pipeline stage
pub fn with_stage(
  factory: ContactFactory,
  stage: PipelineStage,
) -> ContactFactory {
  ContactFactory(..factory, stage: stage)
}

/// Set the profile picture URL
pub fn with_profile_picture_url(
  factory: ContactFactory,
  url: String,
) -> ContactFactory {
  ContactFactory(..factory, profile_picture_url: Some(url))
}

/// Set the notes
pub fn with_notes(factory: ContactFactory, notes: String) -> ContactFactory {
  ContactFactory(..factory, notes: Some(notes))
}

/// Build a Contact domain object (without saving to DB)
/// Useful for testing domain logic or as input to repository methods
pub fn build(factory: ContactFactory) -> Contact {
  // Use epoch timestamp as a dummy value - the database will set the real timestamps
  let dummy_timestamp = timestamp.from_unix_seconds(0)
  Contact(
    id: factory.id,
    first_name: factory.first_name,
    last_name: factory.last_name,
    email: factory.email,
    phone: factory.phone,
    company: factory.company,
    title: factory.title,
    stage: factory.stage,
    profile_picture_url: factory.profile_picture_url,
    notes: factory.notes,
    created_at: dummy_timestamp,
    updated_at: dummy_timestamp,
  )
}

// Helper to convert int to string
fn int_to_string(i: Int) -> String {
  case i {
    0 -> "0"
    1 -> "1"
    2 -> "2"
    3 -> "3"
    4 -> "4"
    5 -> "5"
    6 -> "6"
    7 -> "7"
    8 -> "8"
    9 -> "9"
    _ -> {
      let s = int_to_string(i / 10)
      let digit = int_to_string(i % 10)
      s <> digit
    }
  }
}
