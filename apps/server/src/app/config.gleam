import app/env

pub type Config {
  Config(
    secret_key_base: String,
    db_url: String,
    server_host: String,
    server_port: Int,
  )
}

pub fn load() -> Config {
  let env = env.load()

  Config(
    db_url: env.db_url,
    secret_key_base: env.secret_base_key,
    server_host: env.server_host,
    server_port: env.server_port,
  )
}
