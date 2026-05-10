import gleam/dict
import gleam/int
import gleam/javascript/promise
import gleam/list
import gleam/option.{type Option}
import gleam/result
import gleam/string
import gleam/uri.{type Uri}
import gquery.{type Entry}
import gquery/lustre as gq
import lib/browser
import lib/cache.{type Cache, type InfiniteList}
import lib/contacts/filtering
import lib/contacts/query_builder
import lib/contacts/searching
import lib/contacts/sorting.{
  type SortColumn, CompanyColumn, EmailColumn, NameColumn,
}
import lib/error.{type ApiError}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import route
import service/contact_service
import shared/contacts/contact.{type Contact, type PipelineStage}
import shared/contacts/repository.{type SortDirection, Ascending, ListParams}
import shared/pagination.{type Cursor, type Page}
import view/search_input
import view/stage_badge
import view/stage_filter
import view/table
import virtual_list.{type VirtualItem, type Virtualizer}
import virtual_list/lustre as vlist

// Estimated row height — must match the `h-14` class (56 px). The actual size
// is measured by the virtualizer; this is the placeholder used before the
// ResizeObserver reports back.
pub const item_height = 56

pub const container_id = "contacts-virtual-list"

const overscan = 5

const load_more_threshold = 300

pub type Model {
  Model(
    sort_column: SortColumn,
    sort_direction: SortDirection,
    filter_stage: Option(PipelineStage),
    search: Option(String),
    virtualizer: Virtualizer,
  )
}

pub type Msg {
  UserClickedSort(SortColumn)
  UserClickedContact(Int)
  UserChangedFilter(Option(PipelineStage))
  UserTypedSearch(String)
  ContainerScrolled(Int)
  ContainerResized(Int)
  ItemMeasured(Int, Int)
}

fn build_virtualizer(count: Int) -> Virtualizer {
  let opts =
    virtual_list.Options(
      ..virtual_list.default_options(count, fn(_) { item_height }),
      overscan: overscan,
    )
  virtual_list.new(opts)
}

fn sync_virtualizer_count(v: Virtualizer, count: Int) -> Virtualizer {
  virtual_list.set_count(v, count)
}

pub fn default() -> Model {
  Model(
    sort_column: NameColumn,
    sort_direction: Ascending,
    filter_stage: option.None,
    search: option.None,
    virtualizer: build_virtualizer(0),
  )
}

pub fn from_uri(uri: Uri) -> Model {
  let #(col, dir) = sorting.from_uri(uri)
  Model(
    sort_column: col,
    sort_direction: dir,
    filter_stage: filtering.from_uri(uri),
    search: searching.from_uri(uri),
    virtualizer: build_virtualizer(0),
  )
}

pub fn from_query_string(q: String, scroll: Int) -> Model {
  let base = from_uri(query_builder.to_uri(q))
  Model(
    ..base,
    virtualizer: virtual_list.set_scroll_offset(base.virtualizer, scroll),
  )
}

/// Seed the virtualizer's container size. Used on back-navigation so the
/// first render after popstate already has a visible range (otherwise the
/// virtualizer emits no rows until the resize observer fires, which is too
/// late for the view-transition snapshot).
pub fn with_container_size(model: Model, size: Int) -> Model {
  Model(
    ..model,
    virtualizer: virtual_list.set_container_size(model.virtualizer, size),
  )
}

pub fn cache_key(model: Model) -> String {
  query_builder.build(
    model.sort_column,
    model.sort_direction,
    model.filter_stage,
    model.search,
  )
}

pub fn fetch_effect(
  model: Model,
  cursor: Option(Cursor),
) -> Effect(Result(Page(Contact), ApiError)) {
  use dispatch <- effect.from
  let base = contact_service.default_params()
  contact_service.list(
    ListParams(
      ..base,
      sort_by: sorting.column_to_sort_field(model.sort_column),
      sort_direction: model.sort_direction,
      stage: model.filter_stage,
      search: model.search,
      cursor: cursor,
    ),
  )
  |> promise.tap(dispatch)
  Nil
}

pub fn load(
  model: Model,
  c: Cache,
  placeholder: option.Option(InfiniteList(Contact)),
  on_result: fn(String, Result(Page(Contact), ApiError)) -> msg,
) -> #(Cache, Effect(msg)) {
  let key = cache_key(model)
  let entry = dict.get(c.contacts, key) |> result.unwrap(gquery.NotAsked)
  case entry {
    gquery.Loading(_) | gquery.Loaded(_, _) -> #(c, effect.none())
    gquery.NotAsked | gquery.Failed(_) -> {
      let stale = gquery.stale_for(entry, placeholder)
      let new_entry = gquery.Loading(stale:)
      let eff =
        fetch_effect(model, option.None)
        |> effect.map(fn(r) { on_result(key, r) })
      let new_contacts = dict.insert(c.contacts, key, new_entry)
      #(cache.Cache(..c, contacts: new_contacts), eff)
    }
  }
}

pub fn load_more_if_needed(
  model: Model,
  c: Cache,
  on_result: fn(String, Result(Page(Contact), ApiError)) -> msg,
) -> #(Cache, Effect(msg)) {
  let key = cache_key(model)
  case dict.get(c.contacts, key) {
    Ok(gquery.Loaded(data: il, at: loaded_at)) -> {
      let v = virtual_list.set_count(model.virtualizer, list.length(il.items))
      let total = virtual_list.total_size(v)
      let outer = virtual_list.container_size(v)
      let offset = virtual_list.scroll_offset(v)
      let has_outer = outer > 0
      let near_bottom = offset + outer >= total - load_more_threshold
      case has_outer, near_bottom, il.loading_more, il.next_cursor {
        True, True, False, option.Some(cursor) -> {
          let new_entry =
            gquery.Loaded(data: cache.set_loading_more(il), at: loaded_at)
          let new_contacts = dict.insert(c.contacts, key, new_entry)
          let eff =
            fetch_effect(model, option.Some(cursor))
            |> effect.map(fn(r) { on_result(key, r) })
          #(cache.Cache(..c, contacts: new_contacts), eff)
        }
        _, _, _, _ -> #(c, effect.none())
      }
    }
    _ -> #(c, effect.none())
  }
}

pub fn apply_first_page(
  c: Cache,
  key: String,
  fetch_result: Result(Page(Contact), ApiError),
) -> Cache {
  let il_result =
    fetch_result
    |> result.map(fn(page) {
      cache.from_first_page(page.data, page.next_cursor)
    })
  let entry = gq.record(il_result)
  cache.Cache(..c, contacts: dict.insert(c.contacts, key, entry))
}

pub fn apply_more(
  c: Cache,
  key: String,
  fetch_result: Result(Page(Contact), ApiError),
) -> Cache {
  case dict.get(c.contacts, key), fetch_result {
    Ok(gquery.Loaded(data: il, at: _)), Ok(page) -> {
      let new_il = cache.append_page(il, page.data, page.next_cursor)
      let new_entry = gquery.Loaded(data: new_il, at: gq.now_ms())
      cache.Cache(..c, contacts: dict.insert(c.contacts, key, new_entry))
    }
    Ok(gquery.Loaded(data: il, at: loaded_at)), Error(_) -> {
      let new_entry =
        gquery.Loaded(
          data: cache.InfiniteList(..il, loading_more: False),
          at: loaded_at,
        )
      cache.Cache(..c, contacts: dict.insert(c.contacts, key, new_entry))
    }
    _, _ -> c
  }
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedSort(column) -> {
      let #(new_column, new_dir) = case column == model.sort_column {
        True -> #(column, sorting.toggle_direction(model.sort_direction))
        False -> #(column, Ascending)
      }
      let updated =
        Model(
          ..model,
          sort_column: new_column,
          sort_direction: new_dir,
          virtualizer: virtual_list.set_scroll_offset(model.virtualizer, 0),
        )
      #(updated, push_url(updated))
    }
    UserChangedFilter(stage) -> {
      let updated =
        Model(
          ..model,
          filter_stage: stage,
          virtualizer: virtual_list.set_scroll_offset(model.virtualizer, 0),
        )
      #(updated, push_url(updated))
    }
    UserTypedSearch(query) -> {
      let search = case string.is_empty(query) {
        True -> option.None
        False -> option.Some(query)
      }
      let updated =
        Model(
          ..model,
          search: search,
          virtualizer: virtual_list.set_scroll_offset(model.virtualizer, 0),
        )
      #(updated, push_url(updated))
    }
    UserClickedContact(id) -> {
      let back = cache_key(model)
      let path =
        route.to_path(route.ContactDetail(id))
        <> "?back="
        <> uri.percent_encode(back)
      #(
        model,
        effect.from(fn(_) {
          browser.save_scroll_to_history()
          browser.navigate_with_view_transition(id, path, fn() {
            browser.mark_came_from_contacts()
          })
        }),
      )
    }
    ContainerScrolled(top) -> {
      let v = virtual_list.set_scroll_offset(model.virtualizer, top)
      #(Model(..model, virtualizer: v), effect.none())
    }
    ContainerResized(height) -> {
      let v = virtual_list.set_container_size(model.virtualizer, height)
      #(Model(..model, virtualizer: v), effect.none())
    }
    ItemMeasured(index, size) -> {
      let v = virtual_list.measure_item_at(model.virtualizer, index, size)
      #(Model(..model, virtualizer: v), effect.none())
    }
  }
}

/// Effect that wires up scroll/resize observers for the contacts list. Uses
/// window-scroll mode: the page is the scroll surface, the vlist is just a
/// tall spacer in flow. Call after the route has been entered so the spacer
/// is in the DOM.
pub fn observe_effect() -> Effect(Msg) {
  vlist.observe_window(
    id: container_id,
    on_scroll: ContainerScrolled,
    on_resize: ContainerResized,
    on_measure_item: ItemMeasured,
  )
}

pub fn view(
  model: Model,
  entry: Entry(InfiniteList(Contact), ApiError),
) -> Element(Msg) {
  let is_loading = case entry {
    gquery.Loading(_) -> True
    _ -> False
  }
  let il =
    gquery.get_data(entry)
    |> option.unwrap(cache.InfiniteList(
      items: [],
      next_cursor: option.None,
      loading_more: False,
    ))
  // Keep the virtualizer's count aligned with the loaded items. The router
  // mutates the cache; the page mirrors that into the virtualizer at render
  // time so we don't have to thread another message through.
  let virtualizer =
    sync_virtualizer_count(model.virtualizer, list.length(il.items))
  html.div([attribute.class("space-y-4")], [
    html.h1([attribute.class("text-2xl font-bold text-foreground")], [
      element.text("Contacts"),
    ]),
    html.div([attribute.class("flex flex-col gap-2")], [
      search_input.view(
        value: option.unwrap(model.search, ""),
        placeholder: "Search contacts...",
        on_input: UserTypedSearch,
        debounce_ms: option.Some(300),
        icon: option.Some(
          html.span(
            [
              attribute.class(
                "icon-[lucide--search] text-base text-muted-foreground",
              ),
            ],
            [],
          ),
        ),
        loading: is_loading,
      ),
      stage_filter.view(model.filter_stage, UserChangedFilter),
    ]),
    case il.items, entry {
      [], gquery.NotAsked -> element.none()
      [], gquery.Loading(_) -> view_loading()
      [], _ -> view_empty()
      items, _ ->
        view_table(
          items,
          model.sort_column,
          model.sort_direction,
          is_loading,
          il,
          virtualizer,
        )
    },
  ])
}

fn push_url(model: Model) -> Effect(Msg) {
  modem.push(
    route.to_path(route.Contacts),
    option.Some(cache_key(model)),
    option.None,
  )
}

fn view_loading() -> Element(Msg) {
  html.div(
    [attribute.class("flex justify-center py-20 animate-loading-delayed")],
    [
      html.div(
        [
          attribute.class(
            "w-8 h-8 rounded-full border-2 border-border border-t-faff-pink animate-spin",
          ),
        ],
        [],
      ),
    ],
  )
}

fn view_loading_more() -> Element(Msg) {
  html.div([attribute.class("flex justify-center py-4")], [
    html.div(
      [
        attribute.class(
          "w-5 h-5 rounded-full border-2 border-border border-t-faff-pink animate-spin",
        ),
      ],
      [],
    ),
  ])
}

fn view_end_of_list() -> Element(Msg) {
  html.p([attribute.class("py-6 text-center text-sm text-muted-foreground")], [
    element.text("No more contacts"),
  ])
}

fn view_empty() -> Element(Msg) {
  html.div(
    [
      attribute.class(
        "flex flex-col items-center justify-center py-20 rounded-xl"
        <> " border border-dashed border-border",
      ),
    ],
    [
      html.span(
        [
          attribute.class(
            "icon-[lucide--users] text-4xl text-faff-pink/60 mb-3",
          ),
        ],
        [],
      ),
      html.p([attribute.class("text-sm text-muted-foreground")], [
        element.text("No contacts yet"),
      ]),
    ],
  )
}

fn view_table(
  contacts: List(Contact),
  sort_column: SortColumn,
  sort_direction: SortDirection,
  loading: Bool,
  il: InfiniteList(Contact),
  virtualizer: Virtualizer,
) -> Element(Msg) {
  let cols = columns(sort_column, sort_direction, loading)
  let template = table.grid_template(cols)
  let opacity_class = case loading {
    True -> "opacity-50"
    False -> "opacity-100"
  }
  html.div([attribute.class("animate-content-appear")], [
    html.div([attribute.class("overflow-x-auto")], [
      html.div([attribute.class("min-w-max")], [
        html.div(
          [
            attribute.class(
              "border border-border rounded-xl transition-opacity "
              <> opacity_class,
            ),
          ],
          [
            table.view_header(cols, template),
            vlist.view(
              id: container_id,
              virtualizer: virtualizer,
              render: fn(item: VirtualItem) {
                render_contact_row(contacts, item, cols, template)
              },
              on_scroll: ContainerScrolled,
              attributes: [],
            ),
          ],
        ),
      ]),
    ]),
    case loading {
      True -> element.none()
      False ->
        case il.next_cursor {
          option.Some(_) -> element.none()
          option.None -> view_end_of_list()
        }
    },
    case il.loading_more {
      False -> element.none()
      True -> view_loading_more()
    },
  ])
}

fn render_contact_row(
  contacts: List(Contact),
  item: VirtualItem,
  cols: List(table.Column(Contact, Msg)),
  template: String,
) -> Element(Msg) {
  case nth(contacts, item.index) {
    option.None -> element.none()
    option.Some(contact) ->
      table.view_virtual_row(
        cols,
        contact,
        template,
        option.Some(fn(c: Contact) { UserClickedContact(c.id) }),
        [attribute.attribute("data-contact-id", int.to_string(contact.id))],
      )
  }
}

fn nth(items: List(a), index: Int) -> Option(a) {
  case items, index {
    [], _ -> option.None
    [head, ..], 0 -> option.Some(head)
    [_, ..rest], n -> nth(rest, n - 1)
  }
}

fn columns(
  sort_column: SortColumn,
  sort_direction: SortDirection,
  loading: Bool,
) -> List(table.Column(Contact, Msg)) {
  [
    table.Column(
      header: table.sort_header(
        label: "Name",
        is_active: sort_column == NameColumn,
        ascending: sort_direction == Ascending,
        loading: loading,
        on_click: UserClickedSort(NameColumn),
      ),
      width: "minmax(0, 240px)",
      cell: table.Custom(fn(c: Contact) {
        html.span(
          [
            attribute.class(
              "text-sm font-medium text-foreground truncate w-full min-w-0 vt-contact-name",
            ),
          ],
          [element.text(c.first_name <> " " <> c.last_name)],
        )
      }),
    ),
    table.Column(
      header: table.plain_header("Stage"),
      width: "140px",
      cell: table.Custom(fn(c: Contact) {
        html.div([attribute.class("vt-contact-stage")], [
          stage_badge.view(c.stage),
        ])
      }),
    ),
    table.Column(
      header: table.sort_header(
        label: "Email",
        is_active: sort_column == EmailColumn,
        ascending: sort_direction == Ascending,
        loading: loading,
        on_click: UserClickedSort(EmailColumn),
      ),
      width: "200px",
      cell: table.Custom(fn(c: Contact) {
        html.span(
          [
            attribute.class(
              "text-sm text-muted-foreground truncate block vt-contact-email",
            ),
          ],
          [element.text(c.email)],
        )
      }),
    ),
    table.Column(
      header: table.sort_header(
        label: "Company",
        is_active: sort_column == CompanyColumn,
        ascending: sort_direction == Ascending,
        loading: loading,
        on_click: UserClickedSort(CompanyColumn),
      ),
      width: "160px",
      cell: table.Text(fn(c: Contact) { option.unwrap(c.company, "—") }),
    ),
  ]
}
