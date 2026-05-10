import gleam/dict
import gleam/javascript/promise
import gleam/option.{type Option}
import gleam/result
import gquery.{type Entry}
import gquery/lustre as gq
import lib/browser
import lib/cache
import lib/error.{type ApiError}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import lustre/event
import modem
import route
import service/contact_service
import shared/contacts/contact.{type Contact}
import view/stage_badge

pub type Model {
  Model(contact_id: Int, back_query: Option(String))
}

pub type Msg {
  UserClickedBack
}

pub fn init(id: Int, back_query: Option(String)) -> Model {
  Model(contact_id: id, back_query: back_query)
}

pub fn fetch_effect(id: Int) -> Effect(Result(Contact, ApiError)) {
  use dispatch <- effect.from
  contact_service.get(id)
  |> promise.tap(dispatch)
  Nil
}

pub fn query(
  id: Int,
  c: cache.Cache,
  placeholder: Option(Contact),
  on_result: fn(Int, Result(Contact, ApiError)) -> msg,
) -> #(cache.Cache, Effect(msg)) {
  let entry = dict.get(c.contact, id) |> result.unwrap(gquery.NotAsked)
  let #(new_entry, eff) =
    gq.query(
      entry: entry,
      stale_ms: gquery.never_stale,
      placeholder: placeholder,
      fetch: fetch_effect(id),
      on_result: fn(r) { on_result(id, r) },
    )
  let new_cache =
    cache.Cache(..c, contact: dict.insert(c.contact, id, new_entry))
  #(new_cache, eff)
}

pub fn apply_result(
  c: cache.Cache,
  id: Int,
  fetch_result: Result(Contact, ApiError),
) -> cache.Cache {
  let entry = gq.record(fetch_result)
  cache.Cache(..c, contact: dict.insert(c.contact, id, entry))
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg {
    UserClickedBack ->
      case browser.check_came_from_contacts() {
        True -> #(model, effect.from(fn(_) { browser.history_back() }))
        False -> #(
          model,
          modem.push(
            route.to_path(route.Contacts),
            model.back_query,
            option.None,
          ),
        )
      }
  }
}

pub fn view(_model: Model, entry: Entry(Contact, ApiError)) -> Element(Msg) {
  html.div([attribute.class("space-y-6")], [
    html.button(
      [
        attribute.class(
          "flex items-center gap-1.5 text-sm text-muted-foreground"
          <> " hover:text-foreground transition-colors",
        ),
        attribute.attribute("data-vt", "back"),
        event.on_click(UserClickedBack),
      ],
      [
        html.span(
          [attribute.class("icon-[lucide--arrow-left] text-base shrink-0")],
          [],
        ),
        element.text("Back to Contacts"),
      ],
    ),
    case entry {
      gquery.Loading(option.Some(contact)) -> view_contact(contact)
      gquery.Loading(_) | gquery.NotAsked -> view_skeleton()
      gquery.Failed(err) -> view_error(err)
      gquery.Loaded(contact, _) -> view_contact(contact)
    },
  ])
}

fn view_skeleton() -> Element(Msg) {
  html.div(
    [attribute.class("rounded-xl border border-border bg-card p-6 space-y-4")],
    [
      html.div([attribute.class("flex items-start justify-between gap-4")], [
        html.div(
          [
            attribute.class(
              "h-8 w-56 rounded-md bg-muted animate-pulse leading-tight",
            ),
            attribute.attribute("data-vt", "contact-name"),
            attribute.style("view-transition-name", "contact-name"),
          ],
          [],
        ),
        html.div(
          [
            attribute.class("h-5 w-20 rounded-full bg-muted animate-pulse"),
            attribute.attribute("data-vt", "contact-stage"),
            attribute.style("view-transition-name", "contact-stage"),
          ],
          [],
        ),
      ]),
      html.div([attribute.class("h-px bg-border")], []),
      html.div([attribute.class("flex items-center gap-3")], [
        html.span(
          [
            attribute.class(
              "icon-[lucide--mail] text-lg text-muted-foreground shrink-0",
            ),
          ],
          [],
        ),
        html.div(
          [
            attribute.class("h-4 w-48 rounded bg-muted animate-pulse"),
            attribute.attribute("data-vt", "contact-email"),
            attribute.style("view-transition-name", "contact-email"),
          ],
          [],
        ),
      ]),
    ],
  )
}

fn view_error(err: ApiError) -> Element(Msg) {
  html.div([attribute.class("p-4 rounded-lg bg-red-50 text-red-600 text-sm")], [
    element.text(error.message(err)),
  ])
}

fn view_contact(contact: Contact) -> Element(Msg) {
  html.div(
    [attribute.class("rounded-xl border border-border bg-card p-6 space-y-4")],
    [
      html.div([attribute.class("flex items-start justify-between gap-4")], [
        html.div([attribute.class("space-y-0.5")], [
          html.h1(
            [
              attribute.class(
                "text-2xl font-bold text-foreground leading-tight",
              ),
              attribute.attribute("data-vt", "contact-name"),
              attribute.style("view-transition-name", "contact-name"),
            ],
            [element.text(contact.first_name <> " " <> contact.last_name)],
          ),
        ]),
        html.div(
          [
            attribute.attribute("data-vt", "contact-stage"),
            attribute.style("view-transition-name", "contact-stage"),
          ],
          [stage_badge.view(contact.stage)],
        ),
      ]),
      html.div([attribute.class("h-px bg-border")], []),
      view_field(
        "icon-[lucide--mail]",
        html.a(
          [
            attribute.href("mailto:" <> contact.email),
            attribute.class(
              "text-sm text-foreground hover:text-faff-pink transition-colors",
            ),
            attribute.attribute("data-vt", "contact-email"),
            attribute.style("view-transition-name", "contact-email"),
          ],
          [element.text(contact.email)],
        ),
      ),
    ],
  )
}

fn view_field(icon: String, content: Element(Msg)) -> Element(Msg) {
  html.div([attribute.class("flex items-center gap-3")], [
    html.span(
      [attribute.class(icon <> " text-lg text-muted-foreground shrink-0")],
      [],
    ),
    content,
  ])
}
