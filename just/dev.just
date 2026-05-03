set working-directory := ".."

# Run the server with watchexec, restarting on .gleam file changes
server:
  cd apps/server && watchexec -e gleam -r -- gleam run

# Start lustre dev tools for the client app
# watchexec restarts lustre/dev when shared package changes; lustre handles HMR for client files
client:
  cd apps/client && watchexec -e gleam -w ../shared/src -r -- gleam run -m lustre/dev start

# Start all dev services
run:
  just dev server & just dev client

# Format all apps
format: _server_format _client_format

[private]
_server_format:
  cd apps/server && gleam format src dev test

[private]
_client_format:
  cd apps/client && gleam format src test
