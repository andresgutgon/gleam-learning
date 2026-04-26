# Testing

This guide explains how to set up and run tests for the project.

## Prerequisites

- PostgreSQL 18 running locally (via Docker or native installation)
- Gleam installed
- Just command runner installed

## First Time Setup

### 1. Start PostgreSQL

If using Docker:

```bash
docker-compose up -d
```

This starts PostgreSQL with the credentials defined in your `.env` file.

### 2. Create Test Database

The test database is separate from your development database. Create it with:

```bash
just test setup
```

This command:
- Creates the `gleam_learning_test` database
- Installs the `pg_trgm` extension (for text search)
- Runs all database migrations

## Running Tests

### Run all tests

```bash
gleam test
```

### Run tests with verbose output

```bash
gleam test -- --verbose
```

## How Tests Work

### Test Organization

Tests are located in the `test/` directory, which mirrors the structure of the `src/` directory. This is required by Gleam because test files import dev dependencies (like `gleeunit`) that are not available to application code.

Within the `test/` directory:
- **Test files** (`*_test.gleam`) - Mirror the structure of `src/` (e.g., `test/packages/platform/postgresql/repositories/contacts_test.gleam`)
- **Test factories** (`test/factories/`) - Helpers to build test data
- **Test support utilities** (`test/support/`) - Shared test helpers like database connections

### Test Isolation

Database tests use **transaction-based rollback** for isolation:

```gleam
fn with_test_db(test_fn: fn(repository.Repository) -> a) -> a {
  let assert Ok(db) = db.test_connection()
  db.with_rollback(db, fn(db) {
    let repo = pg_repo.new(db)
    test_fn(repo)
  })
}
```

Each test runs inside a transaction that is rolled back after the test completes. This ensures:
- Tests don't interfere with each other
- No need to manually clean up test data
- Fast test execution

### Environment Configuration

Tests automatically load environment variables from `.env.test` located at the project root. The test helper (`test/support/db.gleam`) loads this file when establishing database connections.

## Test Database Management

### Setup test database (first time)

Create the test database and run all migrations:

```bash
just test setup
```

This command:
- Creates the `gleam_learning_test` database
- Installs the `pg_trgm` extension (for text search)
- Runs all database migrations

### Reset the test database

If your test database gets into a bad state, reset it completely:

```bash
just test reset
```

This drops and recreates the database with all migrations.

## Common Issues

### Tests fail with "database does not exist"

Run `just test setup` to create and migrate the test database.

### Tests fail with "relation does not exist"

Your test database schema is out of date. Run:

```bash
just test reset
```

### PostgreSQL connection refused

Ensure PostgreSQL is running:

```bash
docker-compose ps
```

If not running, start it with `docker-compose up -d`.
