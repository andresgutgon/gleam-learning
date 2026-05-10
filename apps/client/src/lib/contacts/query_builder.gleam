import gleam/list
import gleam/option.{type Option}
import gleam/uri
import lib/contacts/sorting.{type SortColumn}
import shared/contacts/contact.{type PipelineStage, stage_to_param}
import shared/contacts/repository.{type SortDirection}

pub fn build(
  sort_column: SortColumn,
  sort_direction: SortDirection,
  filter_stage: Option(PipelineStage),
  search: Option(String),
) -> String {
  let base = [
    #("sort_by", sorting.column_to_string(sort_column)),
    #("sort_dir", sorting.direction_to_string(sort_direction)),
  ]
  let with_stage = case filter_stage {
    option.None -> base
    option.Some(stage) -> list.append(base, [#("stage", stage_to_param(stage))])
  }
  let with_search = case search {
    option.None -> with_stage
    option.Some(q) -> list.append(with_stage, [#("search", q)])
  }
  uri.query_to_string(with_search)
}

pub fn to_uri(query: String) -> uri.Uri {
  uri.Uri(
    scheme: option.None,
    userinfo: option.None,
    host: option.None,
    port: option.None,
    path: "",
    query: option.Some(query),
    fragment: option.None,
  )
}
