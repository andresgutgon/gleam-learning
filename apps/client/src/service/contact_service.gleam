import gleam/dynamic/decode
import gleam/int
import gleam/javascript/promise.{type Promise}
import gleam/json
import gleam/list
import gleam/option
import gleam/string
import gleam/uri
import lib/api
import lib/error.{type ApiError}
import shared/contacts/contact.{type Contact, type ContactInput, stage_to_param}
import shared/contacts/repository.{
  type ListParams, Descending, ListParams, SortByCreatedAt,
  sort_direction_to_string, sort_field_to_string,
}
import shared/pagination.{type Cursor, type Page, Cursor, Page, encode_cursor}

pub fn default_params() -> ListParams {
  ListParams(
    stage: option.None,
    company: option.None,
    search: option.None,
    email: option.None,
    phone: option.None,
    title: option.None,
    sort_by: SortByCreatedAt,
    sort_direction: Descending,
    cursor: option.None,
    limit: 30,
  )
}

pub fn list(params: ListParams) -> Promise(Result(Page(Contact), ApiError)) {
  { "/api/contacts?" <> build_query(params) }
  |> api.get(page_decoder())
}

pub fn get(id: Int) -> Promise(Result(Contact, ApiError)) {
  { "/api/contacts/" <> int.to_string(id) }
  |> api.get(contact.decoder())
}

pub fn create(input: ContactInput) -> Promise(Result(Contact, ApiError)) {
  let body = contact.input_to_json(input) |> json.to_string
  "/api/contacts"
  |> api.post(contact.decoder(), json: body)
}

pub fn update(
  id: Int,
  input: ContactInput,
) -> Promise(Result(Contact, ApiError)) {
  let body = contact.input_to_json(input) |> json.to_string
  { "/api/contacts/" <> int.to_string(id) }
  |> api.patch(contact.decoder(), json: body)
}

pub fn delete(contact_id: Int) -> Promise(Result(Nil, ApiError)) {
  { "/api/contacts/" <> int.to_string(contact_id) }
  |> api.delete
}

// --- Decoders ---

fn page_decoder() -> decode.Decoder(Page(Contact)) {
  use data <- decode.field("data", decode.list(contact.decoder()))
  use next_cursor <- decode.field(
    "next_cursor",
    decode.optional(cursor_decoder()),
  )
  decode.success(Page(data:, next_cursor:))
}

fn cursor_decoder() -> decode.Decoder(Cursor) {
  use value <- decode.field("value", decode.string)
  use id <- decode.field("id", decode.int)
  decode.success(Cursor(value:, id:))
}

// --- Query string ---

fn build_query(params: ListParams) -> String {
  [
    option.map(params.stage, fn(s) { "stage=" <> stage_to_param(s) }),
    option.map(params.company, fn(c) { "company=" <> c }),
    option.map(params.search, fn(s) { "search=" <> s }),
    option.map(params.email, fn(e) { "email=" <> e }),
    option.map(params.phone, fn(p) { "phone=" <> p }),
    option.map(params.title, fn(t) { "title=" <> t }),
    option.Some("sort_by=" <> sort_field_to_string(params.sort_by)),
    option.Some(
      "sort_direction=" <> sort_direction_to_string(params.sort_direction),
    ),
    option.map(params.cursor, fn(c) { "cursor=" <> cursor_to_param(c) }),
    option.Some("limit=" <> int.to_string(params.limit)),
  ]
  |> list.filter_map(fn(opt) { option.to_result(opt, Nil) })
  |> string.join("&")
}

fn cursor_to_param(cursor: Cursor) -> String {
  encode_cursor(cursor) |> json.to_string |> uri.percent_encode
}
