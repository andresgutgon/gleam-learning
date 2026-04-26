import gleam/erlang/process
import gleam/io
import gleam/otp/actor
import packages/platform/env
import packages/seeds/contacts
import pog

pub fn main() -> Nil {
  // Load environment variables from .env file
  case env.load_dotenv(".env") {
    Ok(_) -> io.println("✓ Loaded .env file")
    Error(e) -> io.println("⚠ Failed to load .env: " <> e)
  }

  // Initialize database connection
  let db_url = env.get_db_url()
  let pool_name = process.new_name("")
  let assert Ok(config) = pog.url_config(pool_name, db_url)
  let assert Ok(actor.Started(_pid, db_pool)) =
    config
    |> pog.pool_size(5)
    |> pog.start()

  // Run seeds
  case contacts.seed(db_pool) {
    Ok(_) -> io.println("✅ Seeding completed successfully")
    Error(e) -> {
      io.println("❌ Seeding failed: " <> e)
      panic as "Seeding failed"
    }
  }
}
