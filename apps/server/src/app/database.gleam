import app/config.{type Config}
import app/context.{type DbPoolName}
import gleam/erlang/process
import gleam/otp/static_supervisor as supervisor
import gleam/result
import pog

pub fn start(config: Config) -> DbPoolName {
  let db_pool_name = process.new_name("db")
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
