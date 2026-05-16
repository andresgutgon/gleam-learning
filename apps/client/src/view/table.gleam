import gleam/list
import gleam/option.{type Option}
import gleam/string
import lustre/attribute
import lustre/element.{type Element}
import lustre/element/html
import lustre/element/keyed
import lustre/event

pub type Cell(row, msg) {
  Text(fn(row) -> String)
  Custom(fn(row) -> Element(msg))
}

pub type Column(row, msg) {
  Column(header: Element(msg), width: String, cell: Cell(row, msg))
}

pub fn view(
  columns: List(Column(row, msg)),
  rows: List(row),
  on_row_click: Option(fn(row) -> msg),
  loading: Bool,
  key: fn(row) -> String,
) -> Element(msg) {
  let template = grid_template(columns)
  let opacity_class = case loading {
    True -> "opacity-50"
    False -> "opacity-100"
  }
  html.div([attribute.class("overflow-x-auto")], [
    html.div([attribute.class("min-w-max")], [
      html.div(
        [
          attribute.class(
            "border border-border rounded-xl overflow-hidden transition-opacity "
            <> opacity_class,
          ),
        ],
        [
          view_header(columns, template),
          keyed.div(
            [],
            list.map(rows, fn(row) {
              #(key(row), view_row(columns, row, template, on_row_click))
            }),
          ),
        ],
      ),
    ]),
  ])
}

pub fn grid_template(columns: List(Column(row, msg))) -> String {
  list.map(columns, fn(c) { c.width })
  |> string.join(" ")
}

pub fn view_header(
  columns: List(Column(row, msg)),
  template: String,
) -> Element(msg) {
  html.div(
    [
      attribute.style("grid-template-columns", template),
      attribute.class(
        "grid items-center gap-4 px-4 py-3 bg-muted/40 border-b border-border",
      ),
    ],
    list.map(columns, fn(c) { c.header }),
  )
}

pub fn plain_header(label: String) -> Element(msg) {
  html.span(
    [
      attribute.class(
        "text-xs font-semibold uppercase tracking-wider text-muted-foreground",
      ),
    ],
    [element.text(label)],
  )
}

pub fn sort_header(
  label label: String,
  is_active is_active: Bool,
  ascending ascending: Bool,
  loading loading: Bool,
  on_click on_click: msg,
) -> Element(msg) {
  let text_class = case is_active {
    True -> "text-foreground"
    False -> "text-muted-foreground"
  }
  html.button(
    [
      attribute.class(
        "flex items-center gap-1 text-xs font-semibold uppercase tracking-wider"
        <> " hover:text-foreground transition-colors "
        <> text_class,
      ),
      event.on_click(on_click),
    ],
    [
      element.text(label),
      case is_active, ascending, loading {
        False, _, _ ->
          html.span(
            [
              attribute.class(
                "icon-[lucide--chevrons-up-down] text-base shrink-0",
              ),
            ],
            [],
          )
        True, _, True ->
          html.span(
            [
              attribute.class(
                "icon-[lucide--loader-circle] text-base shrink-0 animate-spin",
              ),
            ],
            [],
          )
        True, True, False ->
          html.span(
            [attribute.class("icon-[lucide--arrow-up-a-z] text-base shrink-0")],
            [],
          )
        True, False, False ->
          html.span(
            [
              attribute.class(
                "icon-[lucide--arrow-down-a-z] text-base shrink-0",
              ),
            ],
            [],
          )
      },
    ],
  )
}

fn render_cell(cell: Cell(row, msg), row: row) -> Element(msg) {
  case cell {
    Text(f) ->
      html.span(
        [attribute.class("text-sm text-muted-foreground truncate block")],
        [element.text(f(row))],
      )
    Custom(f) ->
      html.div([attribute.class("flex items-center min-w-0")], [f(row)])
  }
}

fn view_row(
  columns: List(Column(row, msg)),
  row: row,
  template: String,
  on_row_click: Option(fn(row) -> msg),
) -> Element(msg) {
  let base_attrs = [
    attribute.style("grid-template-columns", template),
    attribute.class(
      "grid items-center gap-4 h-14 px-4"
      <> " border-b border-border last:border-b-0"
      <> " border-l-2 border-l-transparent"
      <> " hover:border-l-faff-pink hover:bg-faff-pink/5"
      <> " transition-colors cursor-pointer",
    ),
  ]
  let attrs = case on_row_click {
    option.Some(handler) ->
      list.append(base_attrs, [event.on_click(handler(row))])
    option.None -> base_attrs
  }
  html.div(attrs, list.map(columns, fn(c) { render_cell(c.cell, row) }))
}

/// Like `view_row` but without `last:border-b-0`.
/// Use this with virtual lists — the "last rendered" child rotates as the user
/// scrolls, so the CSS `:last-child` selector would flicker on/off.
pub fn view_virtual_row(
  columns: List(Column(row, msg)),
  row: row,
  template: String,
  on_row_click: Option(fn(row) -> msg),
  extra_attrs: List(attribute.Attribute(msg)),
) -> Element(msg) {
  let base_attrs =
    list.append(
      [
        attribute.style("grid-template-columns", template),
        attribute.class(
          "grid items-center gap-4 h-14 px-4"
          <> " border-b border-border"
          <> " border-l-2 border-l-transparent"
          <> " hover:border-l-faff-pink hover:bg-faff-pink/5"
          <> " transition-colors cursor-pointer",
        ),
      ],
      extra_attrs,
    )
  let attrs = case on_row_click {
    option.Some(handler) ->
      list.append(base_attrs, [event.on_click(handler(row))])
    option.None -> base_attrs
  }
  html.div(attrs, list.map(columns, fn(c) { render_cell(c.cell, row) }))
}
