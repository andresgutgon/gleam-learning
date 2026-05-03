import app/context.{type Context, type DbPoolName, TestContext}
import gleam/otp/static_supervisor as supervisor
import gleam/result
import pog
import support/app/test_config

const test_db_pool_name = "test_db_pool"

@external(erlang, "erlang", "binary_to_atom")
fn binary_to_atom(name: String) -> DbPoolName

pub fn db_pool_name() -> DbPoolName {
  binary_to_atom(test_db_pool_name)
}

pub fn start() -> DbPoolName {
  let config = test_config.load()

  let db_pool_name = db_pool_name()
  let db_config =
    pog.url_config(db_pool_name, config.db_url)
    |> result.lazy_unwrap(fn() { panic as "invalid DATABASE_URL" })
  let db_pool = pog.supervised(db_config)
  let assert Ok(_) =
    supervisor.new(supervisor.RestForOne)
    |> supervisor.add(db_pool)
    |> supervisor.start
  db_pool_name
}

pub fn with_rollback(ctx: Context, next: fn(Context) -> Nil) -> Nil {
  let _ =
    pog.transaction(context.db_conn(ctx), fn(db_conn) {
      next(TestContext(config: ctx.config, db_conn:))
      // Always rollback by returning Error
      Error("rollback")
    })
  Nil
}
