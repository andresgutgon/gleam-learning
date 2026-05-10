import gleam/option.{None, Some}
import gleam/uri.{type Uri, Uri}
import gleeunit/should
import lib/contacts/searching

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

pub fn from_uri_no_query_returns_none_test() {
  searching.from_uri(uri_no_query()) |> should.equal(None)
}

pub fn from_uri_empty_query_returns_none_test() {
  searching.from_uri(uri_with_query("")) |> should.equal(None)
}

pub fn from_uri_empty_search_param_returns_none_test() {
  searching.from_uri(uri_with_query("search=")) |> should.equal(None)
}

pub fn from_uri_parses_search_term_test() {
  searching.from_uri(uri_with_query("search=alice"))
  |> should.equal(Some("alice"))
}

pub fn from_uri_preserves_case_test() {
  searching.from_uri(uri_with_query("search=Alice"))
  |> should.equal(Some("Alice"))
}

pub fn from_uri_parses_multi_word_search_test() {
  searching.from_uri(uri_with_query("search=john%20smith"))
  |> should.equal(Some("john smith"))
}

pub fn from_uri_ignores_unrelated_params_test() {
  searching.from_uri(uri_with_query("sort_by=name&sort_dir=asc"))
  |> should.equal(None)
}

pub fn from_uri_search_alongside_other_params_test() {
  searching.from_uri(uri_with_query("sort_by=name&search=bob&stage=lead"))
  |> should.equal(Some("bob"))
}
