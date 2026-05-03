# Gleam Shell Console

An interactive Erlang shell with a live database connection for manual testing and exploration.

## Starting the shell

Run from the `apps/server` directory:

```bash
gleam shell
```

Then initialize the DB connection:

```erlang
DbConn = console:init().
```

This enables string display, starts the `pgo` application, loads config from env, starts the DB pool, and returns a `pog.Connection`.

## Setting up the contacts repository

```erlang
Repo = repositories@contacts@repository:new(DbConn).
```

Extract the functions you need via pattern matching (dot notation does not work in the Erlang shell):

```erlang
{repository, Get, List, Create, Update, Delete} = Repo.
```

## Querying contacts

**Get by ID:**

```erlang
{ok, Contact} = Get(1).
```

**List with default params:**

```erlang
Params = {list_params, none, none, none, none, none, none, sort_by_first_name, ascending, none, 10}.
{ok, Page} = List(Params).
```

`ListParams` field order: `stage, company, search, email, phone, title, sort_by, sort_direction, cursor, limit`.

Gleam `Option` values map to `none` or `{some, Value}` in Erlang. Variant names become lowercase atoms — e.g. `SortByCreatedAt` → `sort_by_created_at`, `Descending` → `descending`.

## Encoding to JSON

```erlang
Json = 'shared@contacts@contact':to_json(Contact).
json:to_string(Json).
```

One-liner:

```erlang
{ok, C} = Get(1), json:to_string('shared@contacts@contact':to_json(C)).
```

## Gleam → Erlang module name mapping

Gleam module paths use `/` as the separator; Erlang uses `@`. Modules with non-alphanumeric characters must be quoted with single quotes.

| Gleam | Erlang shell |
|---|---|
| `app/config` | `app@config` |
| `app/database` | `app@database` |
| `repositories/contacts/repository` | `'repositories@contacts@repository'` |
| `shared/contacts/contact` | `'shared@contacts@contact'` |
