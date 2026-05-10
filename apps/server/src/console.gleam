// server/src/console.gleam

import app/config
import app/context.{Context}
import app/database
import gleam/dynamic.{type Dynamic}
import gleam/erlang/atom
import gleam/option.{None}
import pog
import shared/contacts/contact.{type PipelineStage}
import shared/contacts/repository.{
  type ListParams, type SortDirection, type SortField, Ascending, ListParams,
  SortByName,
}

@external(erlang, "shell", "strings")
fn shell_strings(enabled: Bool) -> Dynamic

@external(erlang, "application", "ensure_all_started")
fn ensure_all_started(app: atom.Atom) -> Dynamic

pub fn init() -> pog.Connection {
  let _ = shell_strings(True)
  let _ = ensure_all_started(atom.create("pgo"))
  let config = config.load()
  let db_pool_name = database.start(config)
  let context = Context(config:, db_pool_name:)
  context.db_conn(context)
}

pub fn default_list_params() -> ListParams {
  ListParams(
    stage: None,
    company: None,
    search: None,
    email: None,
    phone: None,
    title: None,
    sort_by: SortByName,
    sort_direction: Ascending,
    cursor: None,
    limit: 10,
  )
}

pub fn build_list_params(update: fn(ListParams) -> ListParams) -> ListParams {
  default_list_params() |> update
}

pub fn with_limit(params: ListParams, limit: Int) -> ListParams {
  ListParams(..params, limit:)
}

pub fn with_search(params: ListParams, search: String) -> ListParams {
  ListParams(..params, search: option.Some(search))
}

pub fn with_stage(params: ListParams, stage: PipelineStage) -> ListParams {
  ListParams(..params, stage: option.Some(stage))
}

pub fn with_sort(
  params: ListParams,
  sort_by: SortField,
  sort_direction: SortDirection,
) -> ListParams {
  ListParams(..params, sort_by:, sort_direction:)
}
