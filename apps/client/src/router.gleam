import gleam/dict
import gleam/list
import gleam/option
import gleam/result
import gleam/uri.{type Uri}
import gquery
import lib/browser
import lib/cache.{type Cache}
import lib/error.{type ApiError}
import lustre/attribute
import lustre/effect.{type Effect}
import lustre/element.{type Element}
import lustre/element/html
import modem
import page/contact_detail
import page/contacts
import route
import shared/contacts/contact.{type Contact}
import shared/pagination.{type Page as ContactPage}
import view/layout

pub type Model {
  Model(page: AppPage, cache: Cache)
}

pub type AppPage {
  ContactsPage(contacts.Model)
  // The contacts model is preserved across the detail-page detour so back
  // navigation restores virtualizer state (scroll_offset, container_size,
  // item measurements) without reconstruction — the view-transition snapshot
  // needs the matching row in the DOM at the right position immediately.
  ContactDetailPage(
    detail: contact_detail.Model,
    previous_contacts: option.Option(contacts.Model),
  )
}

pub type Msg {
  OnRouteChanged(Uri)
  ContactsPageSentMsg(contacts.Msg)
  ContactDetailPageSentMsg(contact_detail.Msg)
  CacheGotContacts(String, Result(ContactPage(Contact), ApiError))
  CacheGotMoreContacts(String, Result(ContactPage(Contact), ApiError))
  CacheGotContact(Int, Result(Contact, ApiError))
}

pub fn init(initial_uri: Result(Uri, Nil)) -> #(Model, Effect(Msg)) {
  let model = case initial_uri |> result.map(page_from_uri) {
    Ok(#(page, cache, eff)) -> #(Model(page:, cache:), eff)
    Error(_) -> {
      let #(page, cache, eff) = page_from_route(route.home_route)
      #(Model(page:, cache:), eff)
    }
  }
  model
}

pub fn on_url_change(uri: Uri) -> Msg {
  OnRouteChanged(uri)
}

pub fn update(model: Model, msg: Msg) -> #(Model, Effect(Msg)) {
  case msg, model.page {
    OnRouteChanged(uri), _ ->
      case route.from_uri(uri), model.page {
        // Sort/filter/search changes while on contacts — re-query cache, no forced refetch.
        route.Contacts, ContactsPage(_) -> #(model, effect.none())

        // Back from detail. When contacts was preserved, no work is needed —
        // its DOM has been mounted underneath the detail overlay the whole
        // time; we just flip the state to remove the overlay. Direct-load
        // fallback rebuilds the contacts model from the back_query.
        route.Contacts, ContactDetailPage(detail_model, previous_contacts) -> {
          case previous_contacts {
            option.Some(m) -> #(
              Model(page: ContactsPage(m), cache: model.cache),
              effect.none(),
            )
            option.None -> {
              let scroll = browser.read_scroll_from_history()
              let viewport = browser.window_inner_height()
              let base = case detail_model.back_query {
                option.None -> contacts.default()
                option.Some(q) -> contacts.from_query_string(q, scroll)
              }
              let contacts_model = contacts.with_container_size(base, viewport)
              let #(new_cache, fetch_eff) =
                contacts.load(
                  contacts_model,
                  model.cache,
                  option.None,
                  CacheGotContacts,
                )
              let observe_eff =
                contacts.observe_effect() |> effect.map(ContactsPageSentMsg)
              let scroll_eff =
                effect.from(fn(_) { browser.scroll_window_to(scroll) })
              #(
                Model(page: ContactsPage(contacts_model), cache: new_cache),
                effect.batch([fetch_eff, observe_eff, scroll_eff]),
              )
            }
          }
        }

        // Navigate to a contact. Capture the current contacts model so back
        // can restore it without reconstruction. Also pull the row's data
        // out of the list cache as a placeholder so the detail page renders
        // the real name/stage/email immediately — the view-transition morph
        // looks the same whether or not the full contact is cached.
        route.ContactDetail(id), _ -> {
          let detail_model = contact_detail.init(id, back_query_from_uri(uri))
          let previous_contacts = case model.page {
            ContactsPage(m) -> option.Some(m)
            ContactDetailPage(_, prev) -> prev
          }
          let placeholder = case previous_contacts {
            option.Some(m) -> find_contact_in_list(model.cache, m, id)
            option.None -> option.None
          }
          let #(new_cache, fetch_eff) =
            contact_detail.query(id, model.cache, placeholder, CacheGotContact)
          #(
            Model(
              page: ContactDetailPage(detail_model, previous_contacts),
              cache: new_cache,
            ),
            fetch_eff,
          )
        }
      }

    // All contacts page messages first run through contacts.update so the
    // virtualizer sees scroll/resize/measure events. Then we decide whether
    // anything should hit the cache (initial fetch / next-page fetch).
    ContactsPageSentMsg(page_msg), ContactsPage(page_model) -> {
      let #(new_page_model, page_eff) = contacts.update(page_model, page_msg)
      let #(new_cache, cache_eff) = case page_msg {
        // Virtualizer-driven messages don't change the query identity, but
        // they do change scroll/size state — re-evaluate load_more.
        contacts.ContainerScrolled(_)
        | contacts.ContainerResized(_)
        | contacts.ItemMeasured(_, _) ->
          contacts.load_more_if_needed(
            new_page_model,
            model.cache,
            CacheGotMoreContacts,
          )

        _ -> {
          let placeholder =
            dict.get(model.cache.contacts, contacts.cache_key(page_model))
            |> result.map(gquery.get_data)
            |> result.unwrap(option.None)
          contacts.load(
            new_page_model,
            model.cache,
            placeholder,
            CacheGotContacts,
          )
        }
      }
      #(
        Model(page: ContactsPage(new_page_model), cache: new_cache),
        effect.batch([effect.map(page_eff, ContactsPageSentMsg), cache_eff]),
      )
    }

    ContactDetailPageSentMsg(page_msg), ContactDetailPage(page_model, prev) -> {
      let #(new_page_model, page_eff) =
        contact_detail.update(page_model, page_msg)
      #(
        Model(..model, page: ContactDetailPage(new_page_model, prev)),
        effect.map(page_eff, ContactDetailPageSentMsg),
      )
    }

    CacheGotContacts(key, fetch_result), _ -> {
      let new_cache = contacts.apply_first_page(model.cache, key, fetch_result)
      // First-page-loaded: install the DOM observers now that the spacer is
      // about to mount. They'll dispatch the initial container_size + scroll
      // offset, which in turn drives load_more if the page didn't fill the
      // viewport.
      let observe_eff =
        contacts.observe_effect() |> effect.map(ContactsPageSentMsg)
      #(Model(..model, cache: new_cache), observe_eff)
    }

    CacheGotMoreContacts(key, fetch_result), _ -> {
      let new_cache = contacts.apply_more(model.cache, key, fetch_result)
      #(Model(..model, cache: new_cache), effect.none())
    }

    CacheGotContact(id, fetch_result), _ -> {
      let new_cache = contact_detail.apply_result(model.cache, id, fetch_result)
      #(Model(..model, cache: new_cache), effect.none())
    }

    _, _ -> #(model, effect.none())
  }
}

pub fn view(model: Model) -> Element(Msg) {
  // Contacts stays mounted whenever we have a model for it (current page or
  // preserved through a detail-page detour). Detail renders as a fixed-position
  // overlay above it. This avoids re-mounting the virtualizer on back, which
  // is what makes the view-transition snapshot reliable.
  let contacts_model = case model.page {
    ContactsPage(m) -> option.Some(m)
    ContactDetailPage(_, prev) -> prev
  }
  let contacts_layer = case contacts_model {
    option.Some(m) -> {
      let key = contacts.cache_key(m)
      let entry =
        dict.get(model.cache.contacts, key)
        |> result.unwrap(gquery.NotAsked)
      contacts.view(m, entry) |> element.map(ContactsPageSentMsg)
    }
    option.None -> element.none()
  }
  let detail_layer = case model.page {
    ContactDetailPage(detail, _) -> {
      let entry =
        dict.get(model.cache.contact, detail.contact_id)
        |> result.unwrap(gquery.NotAsked)
      html.div(
        [
          attribute.class("fixed inset-0 z-[60] bg-background overflow-auto"),
        ],
        [
          layout.view(
            contact_detail.view(detail, entry)
            |> element.map(ContactDetailPageSentMsg),
          ),
        ],
      )
    }
    ContactsPage(_) -> element.none()
  }
  layout.view(html.div([], [contacts_layer, detail_layer]))
}

// --- Init helpers ---

fn page_from_uri(uri: Uri) -> #(AppPage, Cache, Effect(Msg)) {
  let r = route.from_uri(uri)
  let redirect = case uri.path_segments(uri.path) {
    [] -> modem.replace(route.to_path(r), option.None, option.None)
    _ -> effect.none()
  }
  let empty = cache.empty()
  case r {
    route.Contacts -> {
      let contacts_model = contacts.from_uri(uri)
      let #(new_cache, fetch_eff) =
        contacts.load(contacts_model, empty, option.None, CacheGotContacts)
      #(
        ContactsPage(contacts_model),
        new_cache,
        effect.batch([fetch_eff, redirect]),
      )
    }
    route.ContactDetail(id) -> {
      let back_query = back_query_from_uri(uri)
      let detail_model = contact_detail.init(id, back_query)
      let #(cache_with_contact, contact_eff) =
        contact_detail.query(id, empty, option.None, CacheGotContact)
      let #(new_cache, contacts_eff) = case back_query {
        option.None -> #(cache_with_contact, effect.none())
        option.Some(q) ->
          contacts.load(
            contacts.from_query_string(q, 0),
            cache_with_contact,
            option.None,
            CacheGotContacts,
          )
      }
      #(
        ContactDetailPage(detail_model, option.None),
        new_cache,
        effect.batch([contact_eff, contacts_eff, redirect]),
      )
    }
  }
}

fn page_from_route(r: route.Route) -> #(AppPage, Cache, Effect(Msg)) {
  let empty = cache.empty()
  case r {
    route.Contacts -> {
      let contacts_model = contacts.default()
      let #(new_cache, fetch_eff) =
        contacts.load(contacts_model, empty, option.None, CacheGotContacts)
      #(ContactsPage(contacts_model), new_cache, fetch_eff)
    }
    route.ContactDetail(id) -> {
      let detail_model = contact_detail.init(id, option.None)
      let #(new_cache, fetch_eff) =
        contact_detail.query(id, empty, option.None, CacheGotContact)
      #(ContactDetailPage(detail_model, option.None), new_cache, fetch_eff)
    }
  }
}

fn back_query_from_uri(uri: Uri) -> option.Option(String) {
  use q <- option.then(uri.query)
  case uri.parse_query(q) {
    Error(_) -> option.None
    Ok(pairs) ->
      pairs
      |> list.find(fn(pair: #(String, String)) { pair.0 == "back" })
      |> result.map(fn(pair: #(String, String)) { pair.1 })
      |> option.from_result
  }
}

/// Look up a contact by id in the list cache for a given contacts model.
/// Returns the Contact from the loaded page if present — used as a placeholder
/// for the detail page so the view-transition morph has real text content
/// to interpolate into instead of an empty skeleton block.
fn find_contact_in_list(
  c: Cache,
  contacts_model: contacts.Model,
  id: Int,
) -> option.Option(Contact) {
  let key = contacts.cache_key(contacts_model)
  use entry <- option.then(dict.get(c.contacts, key) |> option.from_result)
  use il <- option.then(gquery.get_data(entry))
  il.items
  |> list.find(fn(contact: Contact) { contact.id == id })
  |> option.from_result
}
