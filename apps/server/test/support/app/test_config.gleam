import app/config.{type Config, Config}
import app/env

pub fn load() -> Config {
  let env = env.load_test()

  Config(
    db_url: env.db_url,
    secret_key_base: env.secret_base_key,
    server_host: env.server_host,
    server_port: env.server_port,
  )
}
