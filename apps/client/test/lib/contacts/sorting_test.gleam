import gleeunit/should
import lib/contacts/sorting.{CompanyColumn, EmailColumn, NameColumn}
import shared/contacts/repository.{
  Ascending, Descending, SortByCompany, SortByEmail, SortByName,
}

// --- toggle_direction ---

pub fn toggle_direction_ascending_to_descending_test() {
  sorting.toggle_direction(Ascending) |> should.equal(Descending)
}

pub fn toggle_direction_descending_to_ascending_test() {
  sorting.toggle_direction(Descending) |> should.equal(Ascending)
}

// --- column_to_sort_field ---

pub fn column_to_sort_field_name_test() {
  sorting.column_to_sort_field(NameColumn) |> should.equal(SortByName)
}

pub fn column_to_sort_field_email_test() {
  sorting.column_to_sort_field(EmailColumn) |> should.equal(SortByEmail)
}

pub fn column_to_sort_field_company_test() {
  sorting.column_to_sort_field(CompanyColumn) |> should.equal(SortByCompany)
}

// --- column_to_string ---

pub fn column_to_string_name_test() {
  sorting.column_to_string(NameColumn) |> should.equal("name")
}

pub fn column_to_string_email_test() {
  sorting.column_to_string(EmailColumn) |> should.equal("email")
}

pub fn column_to_string_company_test() {
  sorting.column_to_string(CompanyColumn) |> should.equal("company")
}

// --- column_from_string ---

pub fn column_from_string_name_test() {
  sorting.column_from_string("name") |> should.equal(NameColumn)
}

pub fn column_from_string_email_test() {
  sorting.column_from_string("email") |> should.equal(EmailColumn)
}

pub fn column_from_string_company_test() {
  sorting.column_from_string("company") |> should.equal(CompanyColumn)
}

pub fn column_from_string_unknown_falls_back_to_name_test() {
  sorting.column_from_string("unknown") |> should.equal(NameColumn)
}

pub fn column_from_string_empty_falls_back_to_name_test() {
  sorting.column_from_string("") |> should.equal(NameColumn)
}

// --- direction_to_string ---

pub fn direction_to_string_ascending_test() {
  sorting.direction_to_string(Ascending) |> should.equal("asc")
}

pub fn direction_to_string_descending_test() {
  sorting.direction_to_string(Descending) |> should.equal("desc")
}

// --- direction_from_string ---

pub fn direction_from_string_asc_test() {
  sorting.direction_from_string("asc") |> should.equal(Ascending)
}

pub fn direction_from_string_desc_test() {
  sorting.direction_from_string("desc") |> should.equal(Descending)
}

pub fn direction_from_string_unknown_falls_back_to_ascending_test() {
  sorting.direction_from_string("unknown") |> should.equal(Ascending)
}
