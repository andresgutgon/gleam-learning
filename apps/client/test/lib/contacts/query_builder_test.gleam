import gleam/option.{None, Some}
import gleeunit/should
import lib/contacts/query_builder
import lib/contacts/sorting.{CompanyColumn, EmailColumn, NameColumn}
import shared/contacts/contact.{
  ContactStage, CustomerStage, LeadStage, OpportunityStage,
}
import shared/contacts/repository.{Ascending, Descending}

// --- sort only ---

pub fn build_name_ascending_no_filter_no_search_test() {
  query_builder.build(NameColumn, Ascending, None, None)
  |> should.equal("sort_by=name&sort_dir=asc")
}

pub fn build_name_descending_no_filter_no_search_test() {
  query_builder.build(NameColumn, Descending, None, None)
  |> should.equal("sort_by=name&sort_dir=desc")
}

pub fn build_email_ascending_no_filter_no_search_test() {
  query_builder.build(EmailColumn, Ascending, None, None)
  |> should.equal("sort_by=email&sort_dir=asc")
}

pub fn build_email_descending_no_filter_no_search_test() {
  query_builder.build(EmailColumn, Descending, None, None)
  |> should.equal("sort_by=email&sort_dir=desc")
}

pub fn build_company_ascending_no_filter_no_search_test() {
  query_builder.build(CompanyColumn, Ascending, None, None)
  |> should.equal("sort_by=company&sort_dir=asc")
}

// --- stage filter ---

pub fn build_with_contact_stage_test() {
  query_builder.build(NameColumn, Ascending, Some(ContactStage), None)
  |> should.equal("sort_by=name&sort_dir=asc&stage=contact")
}

pub fn build_with_lead_stage_test() {
  query_builder.build(NameColumn, Ascending, Some(LeadStage), None)
  |> should.equal("sort_by=name&sort_dir=asc&stage=lead")
}

pub fn build_with_customer_stage_test() {
  query_builder.build(NameColumn, Ascending, Some(CustomerStage), None)
  |> should.equal("sort_by=name&sort_dir=asc&stage=customer")
}

pub fn build_with_opportunity_stage_test() {
  query_builder.build(NameColumn, Ascending, Some(OpportunityStage), None)
  |> should.equal("sort_by=name&sort_dir=asc&stage=opportunity")
}

// --- search ---

pub fn build_with_search_no_filter_test() {
  query_builder.build(NameColumn, Ascending, None, Some("alice"))
  |> should.equal("sort_by=name&sort_dir=asc&search=alice")
}

pub fn build_with_search_term_with_spaces_test() {
  query_builder.build(NameColumn, Ascending, None, Some("john smith"))
  |> should.equal("sort_by=name&sort_dir=asc&search=john%20smith")
}

// --- all three combined ---

pub fn build_sort_stage_search_combined_test() {
  query_builder.build(EmailColumn, Descending, Some(LeadStage), Some("bob"))
  |> should.equal("sort_by=email&sort_dir=desc&stage=lead&search=bob")
}
