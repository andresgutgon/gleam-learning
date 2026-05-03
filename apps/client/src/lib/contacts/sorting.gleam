import gleam/list
import gleam/option
import gleam/result
import gleam/uri.{type Uri, parse_query}
import shared/contacts/repository.{
  type SortDirection, type SortField, Ascending, Descending, SortByCompany,
  SortByEmail, SortByName,
}

pub type SortColumn {
  NameColumn
  EmailColumn
  CompanyColumn
}

pub fn toggle_direction(direction: SortDirection) -> SortDirection {
  case direction {
    Ascending -> Descending
    Descending -> Ascending
  }
}

pub fn column_to_sort_field(column: SortColumn) -> SortField {
  case column {
    NameColumn -> SortByName
    EmailColumn -> SortByEmail
    CompanyColumn -> SortByCompany
  }
}

pub fn from_uri(uri: Uri) -> #(SortColumn, SortDirection) {
  let pairs = case uri.query {
    option.None -> []
    option.Some(q) -> result.unwrap(parse_query(q), [])
  }
  let col =
    list.key_find(pairs, "sort_by")
    |> result.map(column_from_string)
    |> result.unwrap(NameColumn)
  let dir =
    list.key_find(pairs, "sort_dir")
    |> result.map(direction_from_string)
    |> result.unwrap(Ascending)
  #(col, dir)
}

pub fn column_from_string(s: String) -> SortColumn {
  case s {
    "email" -> EmailColumn
    "company" -> CompanyColumn
    _ -> NameColumn
  }
}

pub fn column_to_string(col: SortColumn) -> String {
  case col {
    NameColumn -> "name"
    EmailColumn -> "email"
    CompanyColumn -> "company"
  }
}

pub fn direction_from_string(s: String) -> SortDirection {
  case s {
    "desc" -> Descending
    _ -> Ascending
  }
}

pub fn direction_to_string(dir: SortDirection) -> String {
  case dir {
    Ascending -> "asc"
    Descending -> "desc"
  }
}
