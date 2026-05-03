# Gleam CRM — Project Stack

## Project requirements

Build a fictional CRM with a contacts list page and a dedicated contact detail
page. Features: infinite scroll, filter/sort, create contacts, edit contacts,
move in pipeline, profile picture upload, and notes. No auth flow needed.

### Contact fields

- First name* (required), Last name* (required), Email* (required), Phone, Company, Title
- Pipeline stage (Lead → Contact → Opportunity → Customer, defaults to Lead)
- Profile picture, Notes, Created at, Updated at

### Pipeline stages

1. **Lead** — Initial contact, no qualification yet
2. **Contact** — Qualified and reached out
3. **Opportunity** — Identified a potential deal
4. **Customer** — Closed/won

### Filtering and sorting

**Filters** (combine with AND logic):

| Filter          | Type   | Behavior                                                    |
|-----------------|--------|-------------------------------------------------------------|
| Search          | Text   | Case-insensitive ILIKE on first_name, last_name, email, company |
| Pipeline stage  | Select | Exact match on `stage` enum                                 |
| Company         | Select | Exact match on `company` (dropdown of existing values)       |

**Sorting:**
- Click column headers to sort (toggles asc/desc)
- Default: `created_at desc` (newest first)
- Sortable columns: first_name, last_name, email, company, created_at
- Changing sort/filters resets the cursor and re-fetches from the beginning

**Cursor-based pagination** for infinite scroll. Search input is debounced
(Lustre v5 built-in throttling for server components).

### Row action menu

Each row has a **3-dot menu** (⋮) with three actions:

| Action           | Opens                 | Component |
|------------------|-----------------------|-----------|
| Edit contact     | Contact edit form     | Modal     |
| Move in pipeline | Pipeline stage picker | Popover   |
| Delete           | Confirmation dialog   | Modal     |

A **"New Contact"** button in the contact list header opens the same contact
form modal (reuse the edit form component, just with an empty model).

### Form validation

All validation is server-side. When the user submits the form, the event goes
over WebSocket to the server component's `update` function. The server validates
and returns a DOM patch — errors appear instantly, no page reload, SPA-feeling.

```gleam
type FormErrors {
  first_name: List(String)
  last_name: List(String)
  email: List(String)
}

type Msg {
  SubmitContactForm(fields: ContactFields)
  ContactSaved(Result(Contact, FormErrors))
}

fn validate(fields: ContactFields) -> Result(ContactFields, FormErrors) {
  let first_name_errors = case fields.first_name {
    "" -> ["First name is required"]
    _  -> []
  }
  let email_errors = case fields.email {
    "" -> ["Email is required"]
    e  -> case string.contains(e, "@") {
      True  -> []
      False -> ["Email must be valid"]
    }
  }
  // ... more validations
  case first_name_errors, email_errors, ... {
    [], [], ... -> Ok(fields)
    _, _, ...   -> Error(FormErrors(first_name:, email_errors:, ...))
  }
}

fn update(model, msg) {
  case msg {
    SubmitContactForm(fields) -> {
      case validate(fields) {
        Ok(fields) -> // save to DB, close modal
        Error(errors) -> #(
          Model(..model, form_errors: errors),
          effect.none(),  // DOM patch shows errors immediately
        )
      }
    }
  }
}
```

**Required fields:** First name, Last name, Email (marked with `*` in the UI).

**Validation rules:**
- Required fields cannot be empty
- Email must contain `@`
- Email must be unique (check DB)

**Error display:** Inline below each field, red text (`text-destructive`).
Multiple errors per field are supported (e.g., "Email is required" + "Email
must be valid"). Errors clear when the user modifies the field or resubmits.

## Tech stack

| Layer         | Tool / Library                                                    |
|---------------|-------------------------------------------------------------------|
| Language      | Gleam                                                             |
| Backend       | Wisp v2.2.2 + Mist (HTTP + WebSocket)                             |
| Frontend      | Lustre v5.6.0 (server components over WebSocket)                  |
| Database      | PostgreSQL 17                                                     |
| Migrations    | Cigogne                                                           |
| SQL client    | Squirrel                                                          |
| Styling       | Tailwind CSS v4 via lustre_dev_tools                              |
| Theme         | CSS variables (shadcn pattern) — light + dark mode                |
| UI components | Lustre HTML primitives + Tailwind, no component library            |
| File uploads  | HTTP POST + Subject notification (LiveView pattern)               |
| Containers    | Docker Compose                                                    |

## Architecture

### Data flow: Lustre server components over WebSocket

The entire MVU loop runs on the server. DOM patches are sent to a 10kb client
runtime over WebSockets. Browser events are sent back to the server. No REST
API, no JSON codecs per endpoint, no client-side state management.

```
Browser event → JSON → WebSocket → Lustre server runtime → DOM patches → JSON → WebSocket → Client runtime
```

**Why server components over SPA:**
- No REST API to build and maintain — all interaction goes through `update`
- No JSON codecs for every endpoint
- Direct access to the database from `update` — no async fetch, no loading states
- Real-time by default — all connected clients see updates immediately
- Less client-side code — the browser is a thin renderer

**Trade-offs:**
- WebSocket required — no progressive enhancement without JS
- Network round-trip per interaction (mitigated by debouncing)
- File uploads need a separate HTTP endpoint
- Server holds state per connected component

### Server-side setup

```
server/src/
├── app.gleam           # Entrypoint: start Lustre runtime + Mist server
├── app/
│   ├── router.gleam    # Route definitions (Wisp pattern matching)
│   └── web.gleam       # Shared middleware stack
```

**Key APIs:**
- `server_component.route("/ws")` — client runtime connects here
- `server_component.method(WebSocket)` — transport method
- `server_component.register_subject(subject)` — register a client for updates
- `server_component.client_message_to_json(msg)` — encode patches for client
- `server_component.runtime_message_decoder()` — decode incoming client events
- `server_component.emit(event, data)` — emit a DOM event to client-side JS
- `server_component.include(["target.id"])` — specify JS event properties to serialize

### Navigation with server components

Lustre has no built-in router and `modem` (the routing library) is client-side
only — it doesn't work with server components. We handle navigation manually.

Based on the production pattern from [Curling IO's admin panel](https://curling.io/blog/live-admin-without-javascript),
which uses the same Lustre server component architecture.

**Architecture: single server component + route state in Model + ~90 lines of client JS**

The server component tracks `current_route` in the Model. The `view` function
pattern-matches on it to render different content. No page reloads, one
WebSocket connection.

```gleam
type Route {
  ContactsList
  ContactDetail(id: Int)
}

type Msg {
  NavigateTo(Route)    // user clicked a link → push to history
  UrlChanged(Route)    // browser back/forward → don't push to history
}
```

**Separate `NavigateTo` from `UrlChanged`** — using one message for both
causes an infinite loop: server pushes URL → browser pushes state → user
hits back → `popstate` → server processes URL → server pushes URL again.
`NavigateTo` pushes to history, `UrlChanged` doesn't.

**Navigation links** use `prevent_default` to avoid full page reload while
preserving `<a>` semantics (accessibility, open-in-new-tab):

```gleam
html.a(
  [
    attribute.href("/contacts/" <> int.to_string(contact.id)),
    event.prevent_default(event.on_click(NavigateTo(ContactDetail(contact.id)))),
  ],
  [html.text(contact.name)],
)
```

**Client-server communication for navigation** — use a hidden `<input>` inside
the shadow DOM, not custom events. Regular DOM events don't cross the shadow
DOM boundary reliably, but form element events bubble through Lustre's internal
wiring. This is the pattern proven in production by Curling IO:

```gleam
// In the view, include a hidden input for navigation
html.input([
  attribute.type_("hidden"),
  attribute.id("navigate-url"),
  event.on("change", fn(event) {
    use url <- decode.at(["target", "value"], decode.string)
    decode.success(UrlChanged(parse_route(url)))
  }),
])
```

```javascript
// admin-live.js (~90 lines)
const sc = document.querySelector("lustre-server-component");

// Helper: send URL to server component via hidden input
function sendUrl(url) {
  const input = sc.shadowRoot.getElementById("navigate-url");
  input.value = url;
  input.dispatchEvent(new Event("change", { bubbles: true }));
}

// 1. Link clicks: intercept <a> inside shadow DOM
sc.shadowRoot.addEventListener("click", (e) => {
  const a = e.composedPath().find(el => el.tagName === "A");
  if (!a || e.metaKey || e.ctrlKey || a.target === "_blank") return;
  if (a.origin !== location.origin) return;
  e.preventDefault();
  history.pushState({ path: a.pathname }, "", a.pathname);
  sendUrl(a.pathname);
});

// 2. Back/forward: popstate sends URL without pushing to history
window.addEventListener("popstate", () => {
  sendUrl(location.pathname);
});

// 3. Server-initiated navigation (e.g., redirect after save)
sc.addEventListener("navigate", (e) => {
  history.pushState({ path: e.detail }, "", e.detail);
});
```

**Server-side route handling** — Wisp serves the same HTML page for all routes,
passing the initial URL path as a query param so the server component starts
in the correct route:

```gleam
fn handle_request(req) {
  case req.method, wisp.path_segments(req) {
    Get, _ -> serve_app(req)
    _, _ -> wisp.not_found()
  }
}
```

**CSS custom properties** inherit through shadow boundaries (unlike regular
CSS rules). Our theme variables defined on `:root` will be available inside
the server component's shadow DOM automatically. Lustre handles stylesheet
adoption via `adoptedStyleSheets`.

**Routes:**

| Path             | View                    |
|------------------|-------------------------|
| `/`              | Contact list (infinite) |
| `/contacts/:id`  | Contact detail page     |

### Backend routing (Wisp)

No built-in router — pattern match on `wisp.path_segments(req)`:

```gleam
pub fn handle_request(req) {
  use req <- web.middleware(req)

  case wisp.path_segments(req) {
    ["contacts"]       -> contacts(req)
    ["contacts", id]   -> contact(req, id)
    ["upload-avatar"]  -> upload_avatar(req)
    _                  -> wisp.not_found()
  }
}
```

### Client-side JS interop

For features that need JS, use Gleam's FFI + `server_component.emit`:

| Feature         | Approach                                                              |
|-----------------|-----------------------------------------------------------------------|
| `<dialog>`      | Server emits `"open-dialog"` event → client JS calls `showModal()`   |
| Dark mode       | Server emits event → client JS toggles `.dark` on `<html>`           |
| Search debounce | Lustre v5 built-in event throttling — no client JS needed            |
| File uploads    | HTTP POST + Subject notification (see below)                         |

Dark mode preference: respect `prefers-color-scheme` on first load, persist
user choice in `localStorage`.

## File uploads

No ActiveStorage equivalent exists in Gleam. Use the LiveView pattern: files
go over HTTP (multipart), the server notifies the Lustre runtime via OTP
`Subject`.

**Flow:**

1. Server component renders `<input type="file" data-upload="avatar">`
2. Client-side JS intercepts `change`, POSTs to `/upload-avatar` via `fetch()`
3. Wisp handler receives file via `require_form`, saves to disk with `simplifile`
4. Wisp handler sends `AvatarUploaded(url)` to the Lustre runtime via `Subject`
5. Lustre `update` handles the message, Model updates, DOM patch is pushed to client

**Why Subject notification (not client-side WebSocket callback):**
- Server is the source of truth (file could fail to save)
- No race conditions between HTTP response and WebSocket message
- Follows the Lustre pub/sub example pattern
- DOM updates automatically through normal render cycle

**Storage:** Local filesystem for this learning project. S3 can be added later
by changing the Wisp upload handler — the Subject notification pattern stays
the same.

**Packages:** `simplifile` (file I/O), `marceau` (MIME detection), `filepath`
(path manipulation), `ansel` (image processing if needed).

## Database

### Indexes

Migrations must include these indexes for efficient filtering, sorting, and
cursor-based pagination:

| Index | On | For |
|-------|----|-----|
| `idx_contacts_stage` | `contacts(stage)` | Pipeline stage filter |
| `idx_contacts_company` | `contacts(company)` | Company filter |
| `idx_contacts_created_at_desc` | `contacts(created_at DESC)` | Default sort + cursor pagination |
| `idx_contacts_search_trgm` | `contacts(first_name, last_name, email, company)` using pg_trgm GIN | Text search (ILIKE) |
| `idx_contacts_stage_created_at` | `contacts(stage, created_at DESC)` | Filter by stage + sort by created_at |
| `idx_contacts_company_created_at` | `contacts(company, created_at DESC)` | Filter by company + sort by created_at |
| `idx_contacts_id_created_at` | `contacts(id, created_at DESC)` | Cursor-based pagination keyset lookup |

### PostgreSQL extension

`pg_trgm` is enabled via a database init script, not a migration. Docker
Compose runs it on first container creation.

**`infra/initdb.sh`:**

```sh
#!/bin/bash
set -e

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" <<-EOSQL
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
EOSQL
```

**`docker-compose.yml`:**

```yaml
services:
  db:
    image: postgres:17
    environment:
      POSTGRES_USER: gleam_crm
      POSTGRES_PASSWORD: gleam_crm
      POSTGRES_DB: gleam_crm
    ports:
      - "5432:5432"
    volumes:
      - ./infra/initdb.sh:/docker-entrypoint-initdb.d/01-init.sh
      - pgdata:/var/lib/postgresql/data

volumes:
  pgdata:
```

### Seed data

No standard tool exists. Write a `seed.gleam` module that inserts sample data
via Squirrel-generated queries. Include 50+ contacts to test infinite scroll
and filtering. Call from `main()` before starting the server or as a CLI command.

## UI

### Styling: Tailwind CSS via lustre_dev_tools

Zero-config Tailwind v4 — auto-downloads standalone binary, hot-reloading, no
Node.js needed. If we outgrow it, migrate to Vite later.

### Reusable UI components (shadcn-style)

Build Lustre components that replicate shadcn/ui's visual patterns exactly.
shadcn is just Tailwind classes + CSS variables — no magic. Since we use the
same HSL variable system, we can use the same class compositions to get the
same look and feel.

**1. Button** — shadcn button variants:

```gleam
type ButtonVariant {
  Default    // bg-primary text-primary-foreground
  Destructive
  Outline
  Secondary
  Ghost
  Link
}

fn button(variant: ButtonVariant, attrs: List(Attribute(Msg)), children: List(Element(Msg))) {
  let base = "inline-flex items-center justify-center whitespace-nowrap rounded-md text-sm font-medium ring-offset-background transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50"
  let variant_classes = case variant {
    Default -> "bg-primary text-primary-foreground hover:bg-primary/90"
    Destructive -> "bg-destructive text-destructive-foreground hover:bg-destructive/90"
    Outline -> "border border-input bg-background hover:bg-accent hover:text-accent-foreground"
    Secondary -> "bg-secondary text-secondary-foreground hover:bg-secondary/80"
    Ghost -> "hover:bg-accent hover:text-accent-foreground"
    Link -> "text-primary underline-offset-4 hover:underline"
  }
  html.button([class(base <> " " <> variant_classes), ..attrs], children)
}
```

**2. Input** — shadcn input:

```gleam
fn input(attrs: List(Attribute(Msg))) -> Element(Msg) {
  html.input([class(
    "flex h-10 w-full rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background file:border-0 file:bg-transparent file:text-sm file:font-medium placeholder:text-muted-foreground focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
  ), ..attrs])
}
```

**3. Table** — shadcn table:

```gleam
fn table(attrs: List(Attribute(Msg)), children: List(Element(Msg))) -> Element(Msg) {
  html.table([class("w-full caption-bottom text-sm"), ..attrs], children)
}

fn table_header_row(children: List(Element(Msg))) -> Element(Msg) {
  html.tr([class("border-b bg-muted/50")], [
    html.th([class("h-12 px-4 text-left align-middle font-medium text-muted-foreground")], children)
  ])
}

fn table_row(children: List(Element(Msg))) -> Element(Msg) {
  html.tr([class("border-b transition-colors hover:bg-muted/50")], children)
}

fn table_cell(children: List(Element(Msg))) -> Element(Msg) {
  html.td([class("p-4 align-middle")], children)
}
```

**4. Popover** — positioned floating panel, anchored to trigger via CSS Anchor
Positioning (`anchor-name`, `position-area`, `position-try-fallbacks`). No JS
offset calculations. Clicking outside closes it. Only one open at a time.
Styled as shadcn popover:

```
Popover(trigger, content, is_open)
```

Container classes: `z-50 w-72 rounded-md border bg-popover p-4 text-popover-foreground shadow-md outline-none`

Reusable for: row action menu, pipeline stage picker, filter dropdowns.

**5. Modal (Dialog)** — built on native `<dialog>`. Backdrop, focus trap,
Escape key for free. Open via `showModal()` (triggered by
`server_component.emit` + client-side JS). Styled as shadcn dialog:

```
Modal(title, content, is_open)
```

Container classes: `fixed left-[50%] top-[50%] z-50 grid w-full max-w-lg translate-x-[-50%] translate-y-[-50%] gap-4 border bg-background p-6 shadow-lg duration-200 sm:rounded-lg`

Reusable for: edit contact form, create contact, delete confirmation, add note.

**6. Badge** — for pipeline stage tags:

```gleam
type BadgeVariant {
  Default
  Secondary
  Destructive
  Outline
}

fn badge(variant: BadgeVariant, text: String) -> Element(Msg) {
  let base = "inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-semibold transition-colors focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2"
  let variant_classes = case variant {
    Default -> "border-transparent bg-primary text-primary-foreground hover:bg-primary/80"
    Secondary -> "border-transparent bg-secondary text-secondary-foreground hover:bg-secondary/80"
    Destructive -> "border-transparent bg-destructive text-destructive-foreground hover:bg-destructive/80"
    Outline -> "text-foreground"
  }
  html.div([class(base <> " " <> variant_classes)], [html.text(text)])
}
```

**7. Form field** — label + input + error message:

```gleam
fn field(label_text: String, input_el: Element(Msg), error: Option(String)) -> Element(Msg) {
  html.div([class("space-y-2")], [
    html.label([class("text-sm font-medium leading-none peer-disabled:cursor-not-allowed peer-disabled:opacity-70")], [html.text(label_text)]),
    input_el,
    case error {
      Some(msg) -> html.p([class("text-sm text-destructive")], [html.text(msg)])
      None -> element.none()
    }
  ])
}
```

**Component file structure:**

```
server/src/components/
├── button.gleam        # Button with variants
├── input.gleam         # Styled input
├── table.gleam         # Table, header, row, cell
├── popover.gleam       # Generic Popover component
├── modal.gleam         # Generic Modal (dialog) component
├── badge.gleam         # Badge for pipeline stages
└── field.gleam         # Form field (label + input + error)
```

## Project structure

```
gleam-learning/
├── server/
│   ├── src/
│   │   ├── app.gleam            # Entrypoint: Lustre runtime + Mist server
│   │   ├── app/
│   │   │   ├── router.gleam     # Wisp route definitions
│   │   │   └── web.gleam        # Shared middleware
│   │   ├── components/
│   │   │   ├── button.gleam      # Button with variants
│   │   │   ├── input.gleam       # Styled input
│   │   │   ├── table.gleam       # Table, header, row, cell
│   │   │   ├── popover.gleam     # Generic Popover component
│   │   │   ├── modal.gleam       # Generic Modal (dialog) component
│   │   │   ├── badge.gleam       # Badge for pipeline stages
│   │   │   └── field.gleam       # Form field (label + input + error)
│   │   └── sql/                 # Squirrel SQL queries
│   │       └── *.sql
├── priv/
│   ├── migrations/              # Cigogne migrations
│   └── seed_data/               # SQL seed scripts
├── infra/
│   └── initdb.sh                # Postgres init (pg_trgm extension)
├── docker-compose.yml
└── seed.gleam                   # Seed data module
```
