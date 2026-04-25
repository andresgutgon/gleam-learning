# Development Phases

Each phase is a branch from `main`. When complete, merge back to `main`.

## Phase 1: Hello World — Wisp server

- [x] Initialize Gleam project (`gleam new`)
- [x] Add Wisp + Mist + wisp_mist dependencies
- [x] Create `app.gleam` entrypoint — start Mist server on port 8000
- [x] Create `app/router.gleam` — single route returning "Hello CRM" HTML
- [x] Create `app/web.gleam` — middleware stack (logging, crash rescue, HEAD)
- [x] Run server, verify `http://localhost:8000` shows the page
- [ ] Commit and merge to `main`

## Phase 2: Docker + Postgres + Cigogne

- [ ] Create `docker-compose.yml` with Postgres 17
- [ ] Create `infra/initdb.sh` — enable `pg_trgm` extension
- [ ] Add Cigogne as dev dependency
- [ ] Create initial migration: `contacts` table with all fields + `stage` enum
- [ ] Create `cigogne.toml` config pointing to Docker Postgres
- [ ] Run `gleam run -m cigogne all` — verify migration applies
- [ ] Run `gleam run -m cigogne down` + `gleam run -m cigogne all` — verify rollback/re-apply
- [ ] Commit and merge to `main`

## Phase 3: Squirrel + DB queries

- [ ] Add Squirrel + pog as dependencies
- [ ] Add `blah` as dev dependency for seed data
- [ ] Create `src/sql/` directory with SQL query files:
  - [ ] `list_contacts.sql` — cursor-based pagination with filters + sort
  - [ ] `get_contact.sql` — single contact by ID
  - [ ] `create_contact.sql` — insert new contact
  - [ ] `update_contact.sql` — update contact fields
  - [ ] `delete_contact.sql` — delete by ID
  - [ ] `count_contacts.sql` — total count for "has_more" check
- [ ] Run `gleam run -m squirrel` — verify Gleam code generation
- [ ] Commit and merge to `main`

## Phase 4: Seed data (300 contacts)

- [ ] Create `seed.gleam` module using `blah` for names/emails
- [ ] Define company list (~20 items) and job title list (~20 items)
- [ ] Generate random phone numbers
- [ ] Insert 300 contacts with varied pipeline stages
- [ ] Run seed module — verify 300 rows in DB
- [ ] Commit and merge to `main`

## Phase 5: Lustre server component — static list

- [ ] Add Lustre dependency
- [ ] Define `Model`, `Msg`, `Route` types
- [ ] Implement `init`, `update`, `view` — contacts list loaded from DB
- [ ] Set up WebSocket handler in Mist (`/ws` route)
- [ ] Wire WebSocket to Lustre runtime (`register_subject`, `runtime_message_decoder`, `client_message_to_json`)
- [ ] Render initial HTML shell with `<lustre-server-component>` + script
- [ ] Verify: page loads, WebSocket connects, contacts list renders
- [ ] Commit and merge to `main`

## Phase 6: Tailwind + theme + dark mode

- [ ] Add `lustre_dev_tools` dev dependency
- [ ] Create `assets/theme.css` with HSL variables (light + dark)
- [ ] Create `assets/style.css` with `@import "tailwindcss"` + `@theme` block
- [ ] Configure `gleam.toml` for lustre_dev_tools
- [ ] Build shadcn-style base components:
  - [ ] `button.gleam` — with variants (Default, Destructive, Outline, Secondary, Ghost, Link)
  - [ ] `input.gleam` — styled input
  - [ ] `table.gleam` — table, header, row, cell
  - [ ] `badge.gleam` — pipeline stage badges
- [ ] Style the contacts list table using components
- [ ] Add dark mode toggle (server component emit + client JS)
- [ ] Verify: styled table, dark mode works
- [ ] Commit and merge to `main`

## Phase 7: Navigation

- [ ] Implement `Route` type with `ContactsList` and `ContactDetail(id)` variants
- [ ] Add `NavigateTo` and `UrlChanged` messages (separate to avoid infinite loop)
- [ ] Add hidden `<input>` for navigation communication
- [ ] Create `admin-live.js` (~90 lines) — link click intercept, popstate, pushState
- [ ] Implement `view` pattern matching on route
- [ ] Wisp catch-all route serves same HTML shell, passes initial URL as flags
- [ ] Verify: click contact → detail page, back button → list, URL bar updates
- [ ] Commit and merge to `main`

## Phase 8: Popover + Modal components

- [ ] Build `popover.gleam` — CSS anchor positioning, outside click close
- [ ] Build `modal.gleam` — native `<dialog>`, `showModal()` via emit + client JS
- [ ] Build `field.gleam` — label + input + error message
- [ ] Integrate 3-dot action menu in table rows (Popover)
- [ ] Verify: click ⋮ → menu opens, click outside → closes
- [ ] Commit and merge to `main`

## Phase 9: CRUD — Create, Edit, Delete

- [ ] Implement create contact — "New Contact" button opens Modal with form
- [ ] Implement edit contact — Modal with pre-filled form
- [ ] Server-side form validation (required fields, email format, email uniqueness)
- [ ] Show inline errors below fields on validation failure
- [ ] Implement delete — Modal confirmation → delete from DB
- [ ] Implement move pipeline — Popover with stage picker → update DB
- [ ] Verify: create, edit (with validation), delete, move all work
- [ ] Commit and merge to `main`

## Phase 10: Filtering, sorting, infinite scroll

- [ ] Add search input with debounce (Lustre built-in throttling)
- [ ] Add pipeline stage filter dropdown (Popover)
- [ ] Add company filter dropdown (Popover)
- [ ] Add sortable column headers (click to toggle asc/desc)
- [ ] Implement cursor-based pagination — load 50, scroll to load more
- [ ] Changing filters/sort resets list
- [ ] Verify: search works, filters combine, sort toggles, infinite scroll loads more
- [ ] Commit and merge to `main`

## Phase 11: Profile picture upload

- [ ] Add `upload-avatar` Wisp route (HTTP POST, `require_form`)
- [ ] Save files with `simplifile`, generate unique filenames
- [ ] Create OTP `Subject` for upload notifications in component init
- [ ] Wire Wisp upload handler → Subject → Lustre `update`
- [ ] Client-side JS: intercept file input `change`, POST via `fetch()`
- [ ] Display avatar in contact row and detail page
- [ ] Serve uploaded files via Wisp `serve_static`
- [ ] Verify: upload picture → avatar appears in list
- [ ] Commit and merge to `main`

## Phase 12: Contact detail page

- [ ] Implement `ContactDetail` route view — full contact info
- [ ] Reuse same Modal components for edit, delete, add note
- [ ] Add notes section — list + add new note
- [ ] Verify: navigate to detail, all actions work, notes display
- [ ] Commit and merge to `main`
