import gleam/option.{None, Some}
import gleam/uri.{type Uri, Uri}
import gleeunit/should
import lib/contacts/filtering
import shared/contacts/contact.{
  ContactStage, CustomerStage, LeadStage, OpportunityStage,
}

fn uri_with_query(query: String) -> Uri {
  Uri(
    scheme: None,
    userinfo: None,
    host: None,
    port: None,
    path: "/contacts",
    query: Some(query),
    fragment: None,
  )
}

fn uri_no_query() -> Uri {
  Uri(
    scheme: None,
    userinfo: None,
    host: None,
    port: None,
    path: "/contacts",
    query: None,
    fragment: None,
  )
}

// --- from_uri ---

pub fn from_uri_no_query_returns_none_test() {
  filtering.from_uri(uri_no_query()) |> should.equal(None)
}

pub fn from_uri_empty_query_returns_none_test() {
  filtering.from_uri(uri_with_query("")) |> should.equal(None)
}

pub fn from_uri_parses_contact_stage_test() {
  filtering.from_uri(uri_with_query("stage=contact"))
  |> should.equal(Some(ContactStage))
}

pub fn from_uri_parses_lead_stage_test() {
  filtering.from_uri(uri_with_query("stage=lead"))
  |> should.equal(Some(LeadStage))
}

pub fn from_uri_parses_customer_stage_test() {
  filtering.from_uri(uri_with_query("stage=customer"))
  |> should.equal(Some(CustomerStage))
}

pub fn from_uri_parses_opportunity_stage_test() {
  filtering.from_uri(uri_with_query("stage=opportunity"))
  |> should.equal(Some(OpportunityStage))
}

pub fn from_uri_unknown_stage_returns_none_test() {
  filtering.from_uri(uri_with_query("stage=invalid")) |> should.equal(None)
}

pub fn from_uri_ignores_unrelated_params_test() {
  filtering.from_uri(uri_with_query("sort_by=name&sort_dir=asc"))
  |> should.equal(None)
}

pub fn from_uri_stage_alongside_other_params_test() {
  filtering.from_uri(uri_with_query("sort_by=name&stage=lead"))
  |> should.equal(Some(LeadStage))
}
