import gleam/dynamic/decode
import gleam/int
import gleam/json
import gleam/list
import gleam/option
import shared/contacts/contact
import shared/contacts/repository.{
  type ListParams, Ascending, Descending, ListParams, SortByCompany,
  SortByCreatedAt, SortByEmail, SortByFirstName, SortByLastName, SortByUpdatedAt,
}
import shared/pagination
import wisp.{type Request}

pub fn from_request(request: Request) -> ListParams {
  let query = wisp.get_query(request)
  let get = fn(key) { list.key_find(query, key) |> option.from_result }

  ListParams(
    stage: get("stage") |> option.then(parse_stage),
    company: get("company"),
    search: get("search"),
    email: get("email"),
    phone: get("phone"),
    title: get("title"),
    sort_by: get("sort_by") |> option.map(parse_sort_by) |> option.unwrap(SortByCreatedAt),
    sort_direction: get("sort_direction")
      |> option.map(parse_sort_direction)
      |> option.unwrap(Descending),
    cursor: get("cursor") |> option.then(parse_cursor),
    limit: get("limit")
      |> option.then(fn(s) { int.parse(s) |> option.from_result })
      |> option.unwrap(30),
  )
}

fn parse_stage(s: String) -> option.Option(contact.PipelineStage) {
  case s {
    "lead" -> option.Some(contact.LeadStage)
    "contact" -> option.Some(contact.ContactStage)
    "opportunity" -> option.Some(contact.OpportunityStage)
    "customer" -> option.Some(contact.CustomerStage)
    _ -> option.None
  }
}

fn parse_sort_by(s: String) {
  case s {
    "first_name" -> SortByFirstName
    "last_name" -> SortByLastName
    "email" -> SortByEmail
    "company" -> SortByCompany
    "updated_at" -> SortByUpdatedAt
    _ -> SortByCreatedAt
  }
}

fn parse_sort_direction(s: String) {
  case s {
    "asc" -> Ascending
    _ -> Descending
  }
}

fn parse_cursor(s: String) -> option.Option(pagination.Cursor) {
  let decoder = {
    use value <- decode.field("value", decode.string)
    use id <- decode.field("id", decode.int)
    decode.success(pagination.Cursor(value: value, id: id))
  }
  json.parse(s, decoder) |> option.from_result
}
