import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/uri.{type Uri, parse_query}

pub fn from_uri(uri: Uri) -> Option(String) {
  let pairs = case uri.query {
    option.None -> []
    option.Some(q) -> result.unwrap(parse_query(q), [])
  }
  case list.key_find(pairs, "search") {
    Error(_) -> option.None
    Ok("") -> option.None
    Ok(s) -> option.Some(s)
  }
}
