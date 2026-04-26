import envoy
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/string
import simplifile

/// Load environment variables from a .env file
/// This is called once at startup to load the .env file
pub fn load_dotenv(filepath: String) -> Result(Nil, String) {
  case simplifile.read(filepath) {
    Ok(content) -> {
      content
      |> string.split("\n")
      |> list.each(parse_and_set_line)
      Ok(Nil)
    }
    Error(_) -> Error("Could not read .env file: " <> filepath)
  }
}

fn parse_and_set_line(line: String) -> Nil {
  let line = string.trim(line)

  // Skip empty lines and comments
  case line {
    "" -> Nil
    _ -> {
      case string.starts_with(line, "#") {
        True -> Nil
        False -> {
          case string.split_once(line, "=") {
            Ok(#(key, value)) -> {
              let key = string.trim(key)
              let value = string.trim(value)
              envoy.set(key, value)
              Nil
            }
            Error(_) -> Nil
          }
        }
      }
    }
  }
}

pub fn get_db_url() -> String {
  case envoy.get("DATABASE_URL") {
    Ok(url) -> url
    Error(_) ->
      panic as "DATABASE_URL environment variable is not set. Please ensure it's configured."
  }
}

pub fn get_optional(key: String) -> Option(String) {
  case envoy.get(key) {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}
