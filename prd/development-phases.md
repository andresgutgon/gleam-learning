# Development Phases

Each phase is a branch from `main`. When complete, merge back to `main`.

## Phase 1: Hello World — Wisp server

- [x] Initialize Gleam project (`gleam new`)
- [x] Add Wisp + Mist + wisp_mist dependencies
- [x] Create `src/crm.gleam` entrypoint — start Mist server on port 8000
- [x] Create `src/apps/web/router.gleam` — single route returning "Hello CRM" HTML
- [x] Create `src/apps/web/middleware.gleam` — middleware stack (logging, crash rescue, HEAD)
- [x] Run server, verify `http://localhost:8000` shows the page
- [ ] Commit and merge to `main`

## Phase 2: Docker + Postgres + Cigogne

- [x] Create `docker-compose.yml` with Postgres 17
- [x] Create `infra/initdb.sh` — enable `pg_trgm` extension
- [x] Add Cigogne as dev dependency
- [x] Create `priv/cigogne.toml` config pointing to Docker Postgres
- [x] Add `just/migrations.just` for running migrations
- [x] Create initial migration: `contacts` table with all fields + `stage` enum and `TIMESTAMPTZ`
- [x] Run `gleam run -m cigogne all` — verify migration applies
- [x] Run `gleam run -m cigogne down` + `gleam run -m cigogne all` — verify rollback/re-apply
- [x] Create `docs/migrations.md` explaining how to use Cigogne for migrations
- [x] Commit and merge to `main`

## Phase 3: Repository Pattern — Abstract DB operations

- [x] Define abstract repository interfaces for contacts (ports) in `src/packages/domain/contacts/repository.gleam`
- [x] Implement `pog` adapter for contacts repository (`src/platform/postgresql/repositories/contacts.gleam`)
- [x] Implement mock adapter for contacts repository (`src/domain/contacts/mock_repository.gleam`)
- [x] Create `src/platform/env.gleam` for environment variable loading (critical vs optional)
- [x] Configure dependency injection in `src/crm.gleam` to use the `pog` adapter, reading DB URL from `platform/env`
## Phase 4: Seed data (300 contacts)

### Code Organization
- [x] Create `src/packages/seeds/` package directory
- [x] Seeds package will use `src/packages/platform/postgresql` for DB operations
- [x] Seeds should be idempotent - running twice shouldn't create duplicates (600 contacts)
- [x] Strategy: Use deterministic email addresses (e.g., contact_001@seed.local) as unique keys
- [x] On re-run: UPDATE existing contacts or skip if already exists (check by email)

### Data Generation
- [x] Create seed module using `blah` for realistic names/emails
- [x] Use deterministic approach: Generate emails like `contact_001@seed.local` through `contact_300@seed.local`
- [x] Define company list (~20 items) - cycle through companies deterministically
- [x] Define job title list (~20 items) - cycle through titles deterministically
- [x] Generate random but deterministic phone numbers (seed-based randomness)
- [x] Distribute contacts across all pipeline stages evenly

### Bulk Operations
- [x] Investigate if pog/squirrel supports bulk INSERT operations
- [x] If bulk available: implement batch insert (e.g., 50 contacts at a time)
- [x] If no bulk: implement efficient single inserts with transaction batching
- [x] Add upsert logic: ON CONFLICT (email) DO UPDATE or manual check-then-insert

### Command Execution
- [x] Create `just/seeds.just` file with seed commands
- [x] Investigate Gleam CLI custom commands (can we run `gleam run -m seeds`?)
- [x] Alternative: Create standalone script that compiles and runs seed module
- [ ] Command should accept flags: `--reset` to clear before seeding, `--count N` for custom contact count
- [x] Integrate into justfile: `just seed` or `just seed-reset`
- [x] Add db-reset command for full reset (drop, create, migrate, seed)

### Verification
- [x] Run seed command — verify exactly 300 rows in DB
- [x] Run seed command again — verify still only 300 rows (idempotency)
- [x] Verify data quality: all required fields populated, valid pipeline stages
- [x] Verify distribution: contacts spread across companies, titles, and pipeline stages
- [ ] Commit and merge to `main`

## Phase 4.1: Unit tests for postgreSQL repository
- [ ] Add `gleam_test` dev dependency
- [ ] Investigate factories for test data generation in Gleam community for pog
or with squirrel. If none, create simple helper functions in `contacts_test.gleam` to generate test contacts.
- [ ] Create `src/platform/postgresql/repositories/contacts_test.gleam`
- [ ] Write tests for `list_contacts` with various filters, sorting, pagination
- [ ] Write tests for `get_contact`, `create_contact`, `update_contact`, `delete_contact`
- [ ] Run tests, verify all pass

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
- [ ] Create `src/js/navigation.js` (~90 lines) — link click intercept, popstate, pushState
- [ ] Implement `view` pattern matching on route
- [ ] Wisp catch-all route serves same HTML shell, passes initial URL as flags
- [ ] Verify: click contact → detail page, back button → list, URL bar updates
- [ ] Commit and merge to `main`

## Phase 8: Popover + Modal components

- [ ] Build `src/ui/popover.gleam` — CSS anchor positioning, outside click close
- [ ] Build `src/ui/modal.gleam` — native `<dialog>`, `showModal()` via emit + client JS
- [ ] Build `src/ui/field.gleam` — label + input + error message
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
