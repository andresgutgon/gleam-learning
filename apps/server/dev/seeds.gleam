import env
import gleam/erlang/process
import gleam/io
import gleam/otp/actor
import pog
import seeds/contacts

pub fn main() -> Nil {
  let env_config = env.load()
  let db_url = env_config.db_url
  let pool_name = process.new_name("")
  let assert Ok(config) = pog.url_config(pool_name, db_url)
  let assert Ok(actor.Started(_pid, db_pool)) =
    config
    |> pog.pool_size(5)
    |> pog.start()

  case contacts.seed(db_pool) {
    Ok(_) -> io.println("✅ Seeding completed successfully")
    Error(e) -> {
      io.println("❌ Seeding failed: " <> e)
      panic as "Seeding failed"
    }
  }
}
