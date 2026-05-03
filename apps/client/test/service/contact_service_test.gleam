import gleam/javascript/promise
import gleam/option
import gleam/string
import gleam/time/timestamp
import lib/error
import service/contact_service
import shared/contacts/contact.{Contact, ContactStage, LeadStage}
import shared/contacts/repository.{Ascending, ListParams, SortByName}
import shared/pagination.{Cursor, Page}
import support/mock_fetch

const created_at = "2024-01-01T00:00:00Z"

const alice_json = "{\"id\":1,\"first_name\":\"Alice\",\"last_name\":\"Smith\",\"email\":\"alice@example.com\",\"phone\":null,\"company\":null,\"title\":null,\"stage\":\"Contact\",\"profile_picture_url\":null,\"notes\":null,\"created_at\":\"2024-01-01T00:00:00Z\",\"updated_at\":\"2024-01-01T00:00:00Z\"}"

fn page_json(contacts_json: String, next_cursor_json: String) -> String {
  "{\"data\":["
  <> contacts_json
  <> "],\"next_cursor\":"
  <> next_cursor_json
  <> "}"
}

pub fn list_decodes_contacts_test() {
  mock_fetch.setup(200, page_json(alice_json, "null"))
  contact_service.list(contact_service.default_params())
  |> promise.map(fn(result) {
    let assert Ok(ts) = timestamp.parse_rfc3339(created_at)
    assert result
      == Ok(Page(
        data: [
          Contact(
            id: 1,
            first_name: "Alice",
            last_name: "Smith",
            email: "alice@example.com",
            phone: option.None,
            company: option.None,
            title: option.None,
            stage: ContactStage,
            profile_picture_url: option.None,
            notes: option.None,
            created_at: ts,
            updated_at: ts,
          ),
        ],
        next_cursor: option.None,
      ))
    mock_fetch.teardown()
  })
}

pub fn list_decodes_next_cursor_test() {
  let cursor_json = "{\"value\":\"2024-01-01T00:00:00Z\",\"id\":1}"
  mock_fetch.setup(200, page_json(alice_json, cursor_json))
  contact_service.list(contact_service.default_params())
  |> promise.map(fn(result) {
    let assert Ok(page) = result
    assert page.next_cursor
      == option.Some(Cursor(value: "2024-01-01T00:00:00Z", id: 1))
    mock_fetch.teardown()
  })
}

pub fn list_sends_sort_params_test() {
  mock_fetch.setup(200, page_json(alice_json, "null"))
  let params =
    ListParams(
      ..contact_service.default_params(),
      sort_by: SortByName,
      sort_direction: Ascending,
    )
  contact_service.list(params)
  |> promise.map(fn(_result) {
    let url = mock_fetch.last_request_url()
    assert string.contains(url, "sort_by=name")
    assert string.contains(url, "sort_direction=asc")
    mock_fetch.teardown()
  })
}

pub fn list_sends_filter_params_test() {
  mock_fetch.setup(200, page_json(alice_json, "null"))
  let params =
    ListParams(
      ..contact_service.default_params(),
      stage: option.Some(LeadStage),
      search: option.Some("alice"),
    )
  contact_service.list(params)
  |> promise.map(fn(_result) {
    let url = mock_fetch.last_request_url()
    assert string.contains(url, "stage=lead")
    assert string.contains(url, "search=alice")
    mock_fetch.teardown()
  })
}

pub fn list_sends_cursor_param_test() {
  mock_fetch.setup(200, page_json(alice_json, "null"))
  let params =
    ListParams(
      ..contact_service.default_params(),
      cursor: option.Some(Cursor(value: "2024-01-01T00:00:00Z", id: 1)),
    )
  contact_service.list(params)
  |> promise.map(fn(_result) {
    let url = mock_fetch.last_request_url()
    assert string.contains(url, "cursor=")
    assert string.contains(url, "%7B%22value%22")
    mock_fetch.teardown()
  })
}

pub fn list_returns_error_on_unexpected_status_test() {
  mock_fetch.setup(500, "{\"error\":\"Internal Server Error\"}")
  contact_service.list(contact_service.default_params())
  |> promise.map(fn(result) {
    assert result == Error(error.UnexpectedStatus(500))
    mock_fetch.teardown()
  })
}
