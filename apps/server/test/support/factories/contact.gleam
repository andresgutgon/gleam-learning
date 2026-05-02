import blah/name as blah_name
import gleam/bit_array
import gleam/crypto
import gleam/option.{type Option, None, Some}
import gleam/string
import gleam/time/timestamp
import shared/contacts/contact.{
  type Contact, type PipelineStage, Contact, ContactStage, CustomerStage,
  LeadStage, OpportunityStage,
}

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

pub fn new() -> ContactFactory {
  let first_name = blah_name.first_name()
  let last_name = blah_name.last_name()
  let uid =
    crypto.strong_random_bytes(6)
    |> bit_array.base16_encode
    |> string.lowercase
  ContactFactory(
    id: 0,
    first_name:,
    last_name:,
    email: string.lowercase(first_name)
      <> "."
      <> string.lowercase(last_name)
      <> "+"
      <> uid
      <> "@example.com",
    phone: None,
    company: None,
    title: None,
    stage: LeadStage,
    profile_picture_url: None,
    notes: None,
  )
}

pub fn with_first_name(
  factory: ContactFactory,
  first_name: String,
) -> ContactFactory {
  ContactFactory(..factory, first_name:)
}

pub fn with_last_name(
  factory: ContactFactory,
  last_name: String,
) -> ContactFactory {
  ContactFactory(..factory, last_name:)
}

pub fn with_email(factory: ContactFactory, email: String) -> ContactFactory {
  ContactFactory(..factory, email:)
}

pub fn with_phone(factory: ContactFactory, phone: String) -> ContactFactory {
  ContactFactory(..factory, phone: Some(phone))
}

pub fn with_company(
  factory: ContactFactory,
  company: String,
) -> ContactFactory {
  ContactFactory(..factory, company: Some(company))
}

pub fn with_title(factory: ContactFactory, title: String) -> ContactFactory {
  ContactFactory(..factory, title: Some(title))
}

pub fn with_stage(
  factory: ContactFactory,
  stage: PipelineStage,
) -> ContactFactory {
  ContactFactory(..factory, stage:)
}

pub fn with_profile_picture_url(
  factory: ContactFactory,
  url: String,
) -> ContactFactory {
  ContactFactory(..factory, profile_picture_url: Some(url))
}

pub fn with_notes(factory: ContactFactory, notes: String) -> ContactFactory {
  ContactFactory(..factory, notes: Some(notes))
}

pub fn build(factory: ContactFactory) -> Contact {
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

pub fn build_lead() -> Contact {
  new() |> with_stage(LeadStage) |> build()
}

pub fn build_customer() -> Contact {
  new() |> with_stage(CustomerStage) |> build()
}

pub fn build_opportunity() -> Contact {
  new() |> with_stage(OpportunityStage) |> build()
}

pub fn build_contact_stage() -> Contact {
  new() |> with_stage(ContactStage) |> build()
}
