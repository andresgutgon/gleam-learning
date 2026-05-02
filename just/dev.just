set working-directory := ".."

# Run the server with watchexec, restarting on .gleam file changes
server:
  cd apps/server && watchexec -e gleam -r -- gleam run

# Start all dev services (server only for now)
run:
  just dev server

# Format all apps
format: _server_format

[private]
_server_format:
  cd apps/server && gleam format src dev test
