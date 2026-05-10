import gleam/dynamic/decode
import gleam/fetch
import gleam/int
import gleam/list
import gleam/string

pub type ApiError {
  InvalidUrl(url: String)
  UnexpectedStatus(status: Int)
  FetchError(fetch.FetchError)
  DecodeError(List(decode.DecodeError))
}

pub fn message(error: ApiError) -> String {
  case error {
    InvalidUrl(url) -> "Invalid URL: " <> url
    UnexpectedStatus(status) -> "Unexpected status: " <> int.to_string(status)
    FetchError(fetch.NetworkError(detail)) -> "Network error: " <> detail
    FetchError(fetch.UnableToReadBody) -> "Unable to read response body"
    FetchError(fetch.InvalidJsonBody) -> "Response is not valid JSON"
    DecodeError([]) -> "Failed to decode response"
    DecodeError([first, ..rest]) -> {
      let at = case first.path {
        [] -> ""
        path -> " at " <> string.join(path, ".")
      }
      let suffix = case list.length(rest) {
        0 -> ""
        n -> " (+" <> int.to_string(n) <> " more)"
      }
      "Decode error"
      <> at
      <> ": expected "
      <> first.expected
      <> ", got "
      <> first.found
      <> suffix
    }
  }
}
