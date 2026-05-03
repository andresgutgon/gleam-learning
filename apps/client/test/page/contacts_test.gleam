import gleam/option.{None, Some}
import gleam/uri.{type Uri, Uri}
import gleeunit/should
import lib/contacts/sorting
import page/contacts
import shared/contacts/contact.{ContactStage, LeadStage}
import shared/contacts/repository.{Ascending, Descending}

// --- helpers ---

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

// --- from_uri: sort column ---

pub fn from_uri_defaults_to_name_ascending_test() {
  let model = contacts.from_uri(uri_no_query())
  model.sort_column |> should.equal(sorting.NameColumn)
  model.sort_direction |> should.equal(Ascending)
}

pub fn from_uri_parses_email_column_test() {
  contacts.from_uri(uri_with_query("sort_by=email")).sort_column
  |> should.equal(sorting.EmailColumn)
}

pub fn from_uri_parses_company_column_test() {
  contacts.from_uri(uri_with_query("sort_by=company")).sort_column
  |> should.equal(sorting.CompanyColumn)
}

pub fn from_uri_unknown_sort_by_falls_back_to_name_test() {
  contacts.from_uri(uri_with_query("sort_by=invalid")).sort_column
  |> should.equal(sorting.NameColumn)
}

// --- from_uri: sort direction ---

pub fn from_uri_parses_descending_test() {
  contacts.from_uri(uri_with_query("sort_by=name&sort_dir=desc")).sort_direction
  |> should.equal(Descending)
}

pub fn from_uri_unknown_sort_dir_falls_back_to_ascending_test() {
  contacts.from_uri(uri_with_query("sort_dir=invalid")).sort_direction
  |> should.equal(Ascending)
}

// --- from_uri: stage filter ---

pub fn from_uri_defaults_to_no_filter_test() {
  contacts.from_uri(uri_no_query()).filter_stage
  |> should.equal(None)
}

pub fn from_uri_parses_stage_filter_test() {
  contacts.from_uri(uri_with_query("stage=contact")).filter_stage
  |> should.equal(Some(ContactStage))
}

pub fn from_uri_unknown_stage_falls_back_to_none_test() {
  contacts.from_uri(uri_with_query("stage=invalid")).filter_stage
  |> should.equal(None)
}

// --- from_uri: search ---

pub fn from_uri_defaults_to_no_search_test() {
  contacts.from_uri(uri_no_query()).search
  |> should.equal(None)
}

pub fn from_uri_parses_search_test() {
  contacts.from_uri(uri_with_query("search=alice")).search
  |> should.equal(Some("alice"))
}

pub fn from_uri_empty_search_falls_back_to_none_test() {
  contacts.from_uri(uri_with_query("search=")).search
  |> should.equal(None)
}

// --- cache_key ---

pub fn cache_key_emits_name_ascending_no_filter_by_default_test() {
  contacts.default()
  |> contacts.cache_key
  |> should.equal("sort_by=name&sort_dir=asc")
}

pub fn cache_key_emits_email_descending_test() {
  contacts.Model(
    ..contacts.default(),
    sort_column: sorting.EmailColumn,
    sort_direction: Descending,
  )
  |> contacts.cache_key
  |> should.equal("sort_by=email&sort_dir=desc")
}

pub fn cache_key_includes_stage_filter_test() {
  contacts.Model(..contacts.default(), filter_stage: Some(LeadStage))
  |> contacts.cache_key
  |> should.equal("sort_by=name&sort_dir=asc&stage=lead")
}

pub fn cache_key_includes_search_test() {
  contacts.Model(..contacts.default(), search: Some("alice"))
  |> contacts.cache_key
  |> should.equal("sort_by=name&sort_dir=asc&search=alice")
}

// --- round-trip: cache_key -> from_query_string ---

pub fn round_trip_email_descending_test() {
  let original =
    contacts.Model(
      ..contacts.default(),
      sort_column: sorting.EmailColumn,
      sort_direction: Descending,
    )
  let parsed = contacts.from_query_string(original |> contacts.cache_key, 0)
  parsed.sort_column |> should.equal(sorting.EmailColumn)
  parsed.sort_direction |> should.equal(Descending)
}

pub fn round_trip_stage_filter_test() {
  let original =
    contacts.Model(..contacts.default(), filter_stage: Some(ContactStage))
  let parsed = contacts.from_query_string(original |> contacts.cache_key, 0)
  parsed.filter_stage |> should.equal(Some(ContactStage))
}

pub fn round_trip_search_test() {
  let original = contacts.Model(..contacts.default(), search: Some("alice"))
  let parsed = contacts.from_query_string(original |> contacts.cache_key, 0)
  parsed.search |> should.equal(Some("alice"))
}

// --- update: UserClickedSort ---

pub fn user_clicked_sort_same_column_toggles_direction_test() {
  let model = contacts.Model(..contacts.default(), sort_direction: Ascending)
  let #(updated, _) =
    contacts.update(model, contacts.UserClickedSort(sorting.NameColumn))
  updated.sort_direction |> should.equal(Descending)
}

pub fn user_clicked_sort_descending_toggles_to_ascending_test() {
  let model = contacts.Model(..contacts.default(), sort_direction: Descending)
  let #(updated, _) =
    contacts.update(model, contacts.UserClickedSort(sorting.NameColumn))
  updated.sort_direction |> should.equal(Ascending)
}

pub fn user_clicked_sort_different_column_resets_direction_to_ascending_test() {
  let model =
    contacts.Model(
      ..contacts.default(),
      sort_column: sorting.NameColumn,
      sort_direction: Descending,
    )
  let #(updated, _) =
    contacts.update(model, contacts.UserClickedSort(sorting.EmailColumn))
  updated.sort_column |> should.equal(sorting.EmailColumn)
  updated.sort_direction |> should.equal(Ascending)
}

pub fn user_clicked_sort_preserves_filter_stage_test() {
  let model =
    contacts.Model(..contacts.default(), filter_stage: Some(ContactStage))
  let #(updated, _) =
    contacts.update(model, contacts.UserClickedSort(sorting.EmailColumn))
  updated.filter_stage |> should.equal(Some(ContactStage))
}

pub fn user_clicked_sort_preserves_search_test() {
  let model = contacts.Model(..contacts.default(), search: Some("alice"))
  let #(updated, _) =
    contacts.update(model, contacts.UserClickedSort(sorting.EmailColumn))
  updated.search |> should.equal(Some("alice"))
}

// --- update: UserChangedFilter ---

pub fn user_changed_filter_sets_stage_test() {
  let #(updated, _) =
    contacts.update(
      contacts.default(),
      contacts.UserChangedFilter(Some(LeadStage)),
    )
  updated.filter_stage |> should.equal(Some(LeadStage))
}

pub fn user_changed_filter_clears_stage_test() {
  let model =
    contacts.Model(..contacts.default(), filter_stage: Some(ContactStage))
  let #(updated, _) = contacts.update(model, contacts.UserChangedFilter(None))
  updated.filter_stage |> should.equal(None)
}

pub fn user_changed_filter_preserves_sort_column_test() {
  let model =
    contacts.Model(..contacts.default(), sort_column: sorting.CompanyColumn)
  let #(updated, _) =
    contacts.update(model, contacts.UserChangedFilter(Some(LeadStage)))
  updated.sort_column |> should.equal(sorting.CompanyColumn)
}

pub fn user_changed_filter_preserves_sort_direction_test() {
  let model = contacts.Model(..contacts.default(), sort_direction: Descending)
  let #(updated, _) =
    contacts.update(model, contacts.UserChangedFilter(Some(LeadStage)))
  updated.sort_direction |> should.equal(Descending)
}

pub fn user_changed_filter_preserves_search_test() {
  let model = contacts.Model(..contacts.default(), search: Some("alice"))
  let #(updated, _) =
    contacts.update(model, contacts.UserChangedFilter(Some(LeadStage)))
  updated.search |> should.equal(Some("alice"))
}

// --- update: UserTypedSearch ---

pub fn user_typed_search_sets_search_test() {
  let #(updated, _) =
    contacts.update(contacts.default(), contacts.UserTypedSearch("alice"))
  updated.search |> should.equal(Some("alice"))
}

pub fn user_typed_search_empty_string_clears_search_test() {
  let model = contacts.Model(..contacts.default(), search: Some("alice"))
  let #(updated, _) = contacts.update(model, contacts.UserTypedSearch(""))
  updated.search |> should.equal(None)
}

pub fn user_typed_search_preserves_sort_test() {
  let model =
    contacts.Model(
      ..contacts.default(),
      sort_column: sorting.EmailColumn,
      sort_direction: Descending,
    )
  let #(updated, _) = contacts.update(model, contacts.UserTypedSearch("alice"))
  updated.sort_column |> should.equal(sorting.EmailColumn)
  updated.sort_direction |> should.equal(Descending)
}

pub fn user_typed_search_preserves_filter_stage_test() {
  let model =
    contacts.Model(..contacts.default(), filter_stage: Some(LeadStage))
  let #(updated, _) = contacts.update(model, contacts.UserTypedSearch("alice"))
  updated.filter_stage |> should.equal(Some(LeadStage))
}
// Removed: loading tests — loading is now derived from the cache Entry,
// not stored in contacts.Model.
