set working-directory := "../.."
dc := "docker compose -f just/docker/docker-compose.yml"

# Start services in the background
up:
  {{dc}} up

# Stop services (keeps volumes)
down:
  {{dc}} down

# Stop services and wipe volumes (full reset)
reset:
  {{dc}} down -v

# Tail logs
logs:
  {{dc}} logs -f

# Show status
status:
  {{dc}} ps

psql:
  {{dc}} exec db psql -U gleam_learning_user

