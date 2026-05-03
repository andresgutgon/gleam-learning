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
- [x] Command should accept flags: `--reset` to clear before seeding, `--count N` for custom contact count
- [x] Integrate into justfile: `just seed` or `just seed-reset`
- [x] Add db-reset command for full reset (drop, create, migrate, seed)

### Verification

- [x] Run seed command — verify exactly 300 rows in DB
- [x] Run seed command again — verify still only 300 rows (idempotency)
- [x] Verify data quality: all required fields populated, valid pipeline stages
- [x] Verify distribution: contacts spread across companies, titles, and pipeline stages
- [x] Commit and merge to `main`

## Phase 4.1: Unit tests for PostgreSQL repository

### Implementation Complete ✅

- [x] Test database setup (`gleam_learning_test`) with `.env.test` configuration
- [x] Transaction-based rollback strategy for test isolation (`test/support/db.gleam`)
- [x] GitHub Actions CI workflow with PostgreSQL 16 service container
- [x] Factory pattern implementation (`test/factories/contact.gleam`) with builder-style API
- [x] Test commands via just (`just/test.just`: setup, teardown, migrate, reset, test)
- [x] Comprehensive repository tests (`test/packages/platform/postgresql/repositories/contacts_test.gleam`):
  - [x] **Get contact**: success case, not found error
  - [x] **Create contact**: basic fields, all optional fields
  - [x] **Update contact**: success case, not found error
  - [x] **Delete contact**: success case, not found error
  - [x] **List contacts** - filtering:
    - [x] Empty list
    - [x] Return all contacts
    - [x] Filter by pipeline stage (lead, customer, etc.)
    - [x] Filter by company (partial match with ILIKE)
    - [x] Filter by search term (first name, last name, email, company)
  - [x] **List contacts** - sorting:
    - [x] Sort by first name (ascending)
    - [x] Sort by email (descending)
  - [x] **List contacts** - pagination:
    - [x] Limit results

### Verification

- [x] `gleam test` runs successfully with 16/16 tests passing
- [x] Tests use transaction rollback for isolation (parallel-safe)
- [x] Factory pattern working for test data generation
- [x] GitHub Actions workflow configured (will run on PR)
- [x] Test database provisioning documented in `just/test.just`
- [x] All tests independent and can run in parallel

### Phase 4.2: Advanced repository features
  - [x] Cursor-based pagination (keyset; `Cursor`/`ListResult` types, limit+1 fetch, RFC3339 for timestamps)

## Phase 5: Lustre server component — static list

- [ ] Add Lustre dependency
- [ ] Define `Model`, `Msg`, `Route` types
- [ ] Implement `init`, `update`, `view` — contacts list loaded from DB
- [ ] Verify: page loads, WebSocket connects, contacts list renders
- [ ] Commit and merge to `main`

## Phase 6: Tailwind + theme + dark mode

- [ ] Add `lustre_dev_tools` dev dependency
- [ ] Configure `gleam.toml` for lustre_dev_tools
- [ ] This components should live in `src/packages/ui`. I want to do it in a
    way that in the future can be extacted to a separate package. For do something
    like shadcn-ui but for Gleam. So let's thing all of then in two parts.
    primitive headless unstyled and styled with tailwind and using theme variables.
- [ ] Build shadcn-style base components:
  - [ ] `button.gleam` — with variants (Default, Destructive, Outline, Secondary, Ghost, Link)
  - [ ] `input.gleam` — styled input
  - [ ] `table.gleam` — table, header, row, cell, sorting indicators.
  - [ ] Investigate what's the best way of using an icon library in Gleam. What
        are the alternatives? Is there something like lucide icons?
  - [ ] `badge.gleam` — pipeline stage badges
  - [ ] Build `src/ui/popover.gleam` — CSS anchor positioning, outside click close
- [ ] Style the contacts list table using components
- [ ] Add dark mode toggle (server component emit + client JS)
- [ ] Verify: styled table, dark mode works

## Phase 7: Contacts list view - Infinite pagination, sorting
- [ ] Implement `list_contacts` with pagination, sorting, filtering in repository
- [ ] Add search input with debounce (Lustre built-in throttling)
- [ ] Add pipeline stage filter dropdown (Popover)
- [ ] Add company filter dropdown (Popover)
- [ ] Add sortable column headers (click to toggle asc/desc)
- [ ] Implement cursor-based pagination — load 50, scroll to load more
- [ ] Changing filters/sort resets list
- [ ] Verify: search works, filters combine, sort toggles, infinite scroll loads more

## Phase 7.1: Virtualized list for performance
- [ ] Investigate virtualized list implementations for Lustre or general JS libraries that can be integrated
- [ ] Implement virtualized list in contacts view to handle large datasets efficiently
- [ ] Verify: smooth scrolling and rendering with 300+ contacts, no performance issues
- [ ] How to do windowing/virtualization with server components? We can do it with client JS, but is there a way to do it with Lustre components? Maybe we can implement a `VirtualList` component that only renders visible items and emits events for loading more as the user scrolls. Let's research best practices for this in the context of server components. Add a new `./prd/virtualized-list.md` document to explore this topic in depth.

## Phase 7.2: Implement WebSocket updates for real-time sync
- [ ] Set up WebSocket handler in Mist (`/ws` route)

## Phase 8: Navigation

- [ ] Before nothing let's reconsidere a refactor in the router. Now contacts
      query client and repo is initialized in the crm.gleam. Is a bit weird full app
      knows a specific route. Let's see what community recommends for organizing
      lustre server component apps with multiple routes. Maybe we can move the router to a separate package and make it more agnostic.
- [ ] Implement `Route` type with `ContactsList` and `ContactDetail(id)` variants
- [ ] Add `NavigateTo` and `UrlChanged` messages (separate to avoid infinite loop)
- [ ] Add hidden `<input>` for navigation communication
- [ ] Create `src/js/navigation.js` (~90 lines) — link click intercept, popstate, pushState. Before doing this check if there is already some library that make client side navigation for an app that works with server components. If there is, use it. If not, implement it.
- [ ] Implement `view` pattern matching on route
- [ ] Wisp catch-all route serves same HTML shell, passes initial URL as flags
- [ ] Verify: click contact → detail page, back button → list, URL bar updates
- [ ] Commit and merge to `main`

## Phase 9: Popover + Modal components

- [ ] Build `src/ui/modal.gleam` — native `<dialog>`, `showModal()` via emit + client JS
- [ ] Build `src/ui/field.gleam` — label + input + error message
- [ ] Integrate 3-dot action menu in table rows (Popover)
- [ ] Verify: click ⋮ → menu opens, click outside → closes
- [ ] Commit and merge to `main`

## Phase 10: CRUD — Create, Edit, Delete

- [ ] Implement create contact — "New Contact" button opens Modal with form
- [ ] Implement edit contact — Modal with pre-filled form
- [ ] Server-side form validation (required fields, email format, email uniqueness)
- [ ] Show inline errors below fields on validation failure
- [ ] Implement delete — Modal confirmation → delete from DB
- [ ] Implement move pipeline — Popover with stage picker → update DB
- [ ] Verify: create, edit (with validation), delete, move all work
- [ ] Commit and merge to `main`

## Phase 11: Filtering, sorting, infinite scroll

- [ ] Add search input with debounce (Lustre built-in throttling)
- [ ] Add pipeline stage filter dropdown (Popover)
- [ ] Add company filter dropdown (Popover)
- [ ] Add sortable column headers (click to toggle asc/desc)
- [ ] Implement cursor-based pagination — load 50, scroll to load more
- [ ] Changing filters/sort resets list
- [ ] Verify: search works, filters combine, sort toggles, infinite scroll loads more
- [ ] Commit and merge to `main`

## Phase 12: Profile picture upload

- [ ] Add data model for avatar URL in `contacts` table (nullable)
- [ ] Add `upload-avatar` Wisp route (HTTP POST, `require_form`)
- [ ] Save files with `simplifile`, generate unique filenames
- [ ] Create OTP `Subject` for upload notifications in component init
- [ ] Wire Wisp upload handler → Subject → Lustre `update`
- [ ] Client-side JS: intercept file input `change`, POST via `fetch()`
- [ ] Display avatar in contact row and detail page
- [ ] Serve uploaded files via Wisp `serve_static`
- [ ] Verify: upload picture → avatar appears in list
- [ ] Once this simple updload works. Do a research in `./prd/active-storge.md` about how to implement an active storage like solution in Gleam. Maybe we can create a separate package for file storage that can support multiple backends (local, S3, etc) and has features like direct uploads, variants, etc.

## Phase 13: Contact detail page

- [ ] Implement `ContactDetail` route view — full contact info
- [ ] Reuse same Modal components for edit, delete, add note
- [ ] Add notes section — list + add new note
- [ ] Verify: navigate to detail, all actions work, notes display
- [ ] Verify browser back/forward works correctly with navigation
