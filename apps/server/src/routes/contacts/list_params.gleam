import gleam/int
import gleam/list
import gleam/option
import shared/contacts/contact
import shared/contacts/repository.{
  type ListParams, Descending, ListParams, SortByCreatedAt,
  sort_direction_from_string, sort_field_from_string,
}
import shared/pagination
import wisp.{type Request}

pub fn from_request(request: Request) -> ListParams {
  let query = wisp.get_query(request)
  let get = fn(key) { list.key_find(query, key) |> option.from_result }

  ListParams(
    stage: get("stage") |> option.then(contact.stage_from_param),
    company: get("company"),
    search: get("search"),
    email: get("email"),
    phone: get("phone"),
    title: get("title"),
    sort_by: get("sort_by")
      |> option.map(sort_field_from_string)
      |> option.unwrap(SortByCreatedAt),
    sort_direction: get("sort_direction")
      |> option.map(sort_direction_from_string)
      |> option.unwrap(Descending),
    cursor: get("cursor") |> option.then(pagination.cursor_from_string),
    limit: get("limit")
      |> option.then(fn(s) { int.parse(s) |> option.from_result })
      |> option.unwrap(30),
  )
}
