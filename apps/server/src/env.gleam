import envoy
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Env {
  Env(db_url: String)
}

pub fn load() -> Env {
  ensure_loaded_with([".env", ".env.local"])
  Env(db_url: require("DATABASE_URL"))
}

pub fn load_test() -> Env {
  ensure_loaded_with([".env.test"])
  Env(db_url: require("DATABASE_URL"))
}

pub fn load_from_file(path: String) -> Env {
  case simplifile.read(path) {
    Ok(content) -> apply_dotenv(content)
    Error(_) -> Nil
  }
  Env(db_url: require("DATABASE_URL"))
}

// ---------------------------------------------------------------------------
// Internal: env var lookup helpers
// ---------------------------------------------------------------------------

fn require(key: String) -> String {
  case envoy.get(key) {
    Ok(value) -> value
    Error(_) -> panic as { key <> " environment variable is not set." }
  }
}

// ---------------------------------------------------------------------------
// Internal: dotenv discovery and loading
// ---------------------------------------------------------------------------

// Files whose presence marks a directory as the repo root.
const repo_root_markers = [".git", "justfile"]

fn ensure_loaded_with(candidates: List(String)) -> Nil {
  case simplifile.current_directory() {
    Ok(cwd) ->
      case find_repo_root(cwd) {
        Ok(root) -> try_load_first_dotenv(root, candidates)
        Error(_) -> Nil
      }
    Error(_) -> Nil
  }
}

fn try_load_first_dotenv(root: String, candidates: List(String)) -> Nil {
  case candidates {
    [] -> Nil
    [name, ..rest] -> {
      let path = root <> "/" <> name
      case simplifile.read(path) {
        Ok(content) -> apply_dotenv(content)
        Error(_) -> try_load_first_dotenv(root, rest)
      }
    }
  }
}

fn apply_dotenv(content: String) -> Nil {
  content
  |> string.split("\n")
  |> list.each(parse_and_set_line)
}

fn parse_and_set_line(line: String) -> Nil {
  let line = string.trim(line)
  case line, string.starts_with(line, "#") {
    "", _ -> Nil
    _, True -> Nil
    _, False ->
      case string.split_once(line, "=") {
        Ok(#(key, value)) -> {
          let key = string.trim(key)
          let value = strip_surrounding_quotes(string.trim(value))
          // Skip-if-set: never overwrite a var the platform already provided.
          // This is what makes the .env fallback safe in production.
          case envoy.get(key) {
            Ok(_) -> Nil
            Error(_) -> envoy.set(key, value)
          }
        }
        Error(_) -> Nil
      }
  }
}

fn strip_surrounding_quotes(value: String) -> String {
  let len = string.length(value)
  case len >= 2 {
    False -> value
    True -> {
      let starts_dq = string.starts_with(value, "\"")
      let ends_dq = string.ends_with(value, "\"")
      let starts_sq = string.starts_with(value, "'")
      let ends_sq = string.ends_with(value, "'")
      case starts_dq && ends_dq, starts_sq && ends_sq {
        True, _ -> string.slice(value, 1, len - 2)
        _, True -> string.slice(value, 1, len - 2)
        _, _ -> value
      }
    }
  }
}

// ---------------------------------------------------------------------------
// Internal: walk up from CWD to find the repo root
// ---------------------------------------------------------------------------

fn find_repo_root(start: String) -> Result(String, Nil) {
  case has_any_marker(start, repo_root_markers) {
    True -> Ok(start)
    False -> {
      let parent = parent_dir(start)
      case parent == start {
        True -> Error(Nil)
        // hit filesystem root
        False -> find_repo_root(parent)
      }
    }
  }
}

fn has_any_marker(dir: String, markers: List(String)) -> Bool {
  list.any(markers, fn(m) {
    let path = dir <> "/" <> m
    let is_file = simplifile.is_file(path) |> result.unwrap(False)
    let is_dir = simplifile.is_directory(path) |> result.unwrap(False)
    is_file || is_dir
  })
}

fn parent_dir(path: String) -> String {
  case string.split(path, "/") |> list.reverse {
    [_last, ..rest] ->
      case list.reverse(rest) {
        [] -> "."
        parts -> string.join(parts, "/")
      }
    [] -> "."
  }
}
