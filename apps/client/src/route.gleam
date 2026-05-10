import gleam/int
import gleam/result
import gleam/uri.{type Uri}

pub const home_route = Contacts

pub type Route {
  Contacts
  ContactDetail(id: Int)
}

pub fn to_path(route: Route) -> String {
  case route {
    Contacts -> "/contacts"
    ContactDetail(id) -> "/contacts/" <> int.to_string(id)
  }
}

pub fn from_uri(uri: Uri) -> Route {
  case uri.path_segments(uri.path) {
    ["contacts"] -> Contacts
    ["contacts", id] ->
      int.parse(id)
      |> result.map(ContactDetail)
      |> result.unwrap(home_route)
    _ -> home_route
  }
}
