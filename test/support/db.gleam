//// Test database helpers for managing test database connections,
//// transactions, and test isolation.

import gleam/erlang/process
import gleam/otp/actor
import gleam/result
import packages/platform/env
import pog

/// Get a database connection for testing
pub fn test_connection() -> Result(pog.Connection, String) {
  // Load test environment if not already loaded
  let _ = env.load_dotenv(".env.test")

  let db_url = env.get_db_url()
  let pool_name = process.new_name("")
  let assert Ok(config) = pog.url_config(pool_name, db_url)
  let assert Ok(actor.Started(_pid, db_pool)) =
    config
    |> pog.pool_size(1)
    |> pog.start()

  Ok(db_pool)
}

/// Execute a function within a transaction and rollback afterwards.
/// This ensures test isolation - all database changes are rolled back.
pub fn with_rollback(
  db: pog.Connection,
  test_fn: fn(pog.Connection) -> a,
) -> a {
  // Start transaction
  let assert Ok(_) =
    pog.query("BEGIN")
    |> pog.execute(db)

  // Run test
  let result = test_fn(db)

  // Always rollback, even if test fails
  let assert Ok(_) =
    pog.query("ROLLBACK")
    |> pog.execute(db)

  result
}

/// Clean all data from contacts table (for setup/teardown if needed)
pub fn truncate_contacts(db: pog.Connection) -> Result(Nil, pog.QueryError) {
  pog.query("TRUNCATE TABLE contacts RESTART IDENTITY CASCADE")
  |> pog.execute(db)
  |> result.map(fn(_) { Nil })
}
