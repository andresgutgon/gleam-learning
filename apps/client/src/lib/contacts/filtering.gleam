import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/uri.{type Uri, parse_query}
import shared/contacts/contact.{type PipelineStage, stage_from_param}

pub fn from_uri(uri: Uri) -> Option(PipelineStage) {
  let pairs = case uri.query {
    option.None -> []
    option.Some(q) -> result.unwrap(parse_query(q), [])
  }
  list.key_find(pairs, "stage")
  |> result.try(fn(s) { option.to_result(stage_from_param(s), Nil) })
  |> option.from_result
}
