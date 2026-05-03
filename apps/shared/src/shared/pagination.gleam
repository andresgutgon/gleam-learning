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
