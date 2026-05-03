import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option}
import gquery.{type Entry}
import lib/error.{type ApiError}
import shared/contacts/contact.{type Contact}
import shared/pagination.{type Cursor}

pub type InfiniteList(item) {
  InfiniteList(
    items: List(item),
    next_cursor: Option(Cursor),
    loading_more: Bool,
  )
}

pub fn from_first_page(
  items: List(item),
  next_cursor: Option(Cursor),
) -> InfiniteList(item) {
  InfiniteList(items:, next_cursor:, loading_more: False)
}

pub fn append_page(
  il: InfiniteList(item),
  new_items: List(item),
  next_cursor: Option(Cursor),
) -> InfiniteList(item) {
  InfiniteList(
    items: list.append(il.items, new_items),
    next_cursor:,
    loading_more: False,
  )
}

pub fn set_loading_more(il: InfiniteList(item)) -> InfiniteList(item) {
  InfiniteList(..il, loading_more: True)
}

pub type Cache {
  Cache(
    contacts: Dict(String, Entry(InfiniteList(Contact), ApiError)),
    contact: Dict(Int, Entry(Contact, ApiError)),
  )
}

pub fn empty() -> Cache {
  Cache(contacts: dict.new(), contact: dict.new())
}
