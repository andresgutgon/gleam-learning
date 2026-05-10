import gleam/dynamic/decode
import gleam/json
import gleam/option.{type Option}

/// Keyset pagination cursor. `value` is the text-encoded sort column value at
/// the boundary row; `id` is the primary key used as a tiebreaker.
pub type Cursor {
  Cursor(value: String, id: Int)
}

pub type Page(a) {
  Page(data: List(a), next_cursor: Option(Cursor))
}

pub fn encode_cursor(cursor: Cursor) -> json.Json {
  json.object([
    #("value", json.string(cursor.value)),
    #("id", json.int(cursor.id)),
  ])
}

pub fn cursor_from_string(s: String) -> option.Option(Cursor) {
  let decoder = {
    use value <- decode.field("value", decode.string)
    use id <- decode.field("id", decode.int)
    decode.success(Cursor(value:, id:))
  }
  json.parse(s, decoder) |> option.from_result
}
