import gleam/erlang/process
import gleam/otp/actor
import packages/platform/env
import pog

pub type AppContext {
  AppContext(db: pog.Connection)
}

pub fn start() -> AppContext {
  let env = env.load()

  AppContext(db: start_db(db_url: env.db_url))
}

fn start_db(db_url db_url: String) -> pog.Connection {
  let pool_name = process.new_name("")
  let assert Ok(config) = pog.url_config(pool_name, db_url)
  let assert Ok(actor.Started(_pid, db_pool)) =
    config
    |> pog.pool_size(10)
    |> pog.start()
  db_pool
}
