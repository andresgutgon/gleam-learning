import apps/web/router.{AppConfig}
import gleam/erlang/process
import gleam/io
import gleam/otp/actor
import mist
import packages/domain/contacts/repository as repo
import packages/platform/env
import packages/platform/postgresql/repositories/contacts/repository as contacts_repo
import pog
import wisp
import wisp/wisp_mist

pub fn main() -> Nil {
  // Load environment variables from .env file
  case env.load_dotenv(".env") {
    Ok(_) -> io.println("✓ Loaded .env file")
    Error(e) -> io.println("⚠ Failed to load .env: " <> e)
  }

  wisp.configure_logger()
  let secret_key_base = wisp.random_string(64)

  // Initialize database connection pool using env variables
  let db_url = env.get_db_url()
  let pool_name = process.new_name("")
  let assert Ok(config) = pog.url_config(pool_name, db_url)
  let assert Ok(actor.Started(_pid, db_pool)) =
    config
    |> pog.pool_size(10)
    |> pog.start()

  // Initialize repository adapter
  // Injecting the concrete implementation here
  let contacts_repository: repo.Repository = contacts_repo.new(db_pool)

  let app_config = AppConfig(contacts_repo: contacts_repository)

  let assert Ok(_) =
    router.handle_request(_, app_config)
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.port(8000)
    |> mist.start

  process.sleep_forever()
}
