set working-directory := '..'
# Apply the next migration
up:
    gleam run -m cigogne up

# Roll back the last applied migration
down:
    gleam run -m cigogne down

# Apply all migrations not yet applied
last:
    gleam run -m cigogne last

# Apply/roll back N migrations (positive = apply, negative = roll back)
apply n:
    gleam run -m cigogne apply {{n}}

# Show the last applied migration and the current DB schema
show:
    gleam run -m cigogne show

# Create a new migration with the given name
new name:
    gleam run -m cigogne new {{name}}

# Reset database (drop, create, apply all migrations)
reset:
    @echo "🔄 Resetting database..."
    @echo "⚠️  Warning: This will drop the database and terminate all connections!"
    docker compose exec -T db psql -U ${POSTGRES_USER} -d postgres -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${POSTGRES_DB}' AND pid <> pg_backend_pid();" > /dev/null 2>&1 || true
    sleep 1
    docker compose exec -T db dropdb -U ${POSTGRES_USER} --if-exists --force ${POSTGRES_DB}
    docker compose exec -T db createdb -U ${POSTGRES_USER} ${POSTGRES_DB}
    docker compose exec -T db psql -U ${POSTGRES_USER} -d ${POSTGRES_DB} -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;"
    @echo "✅ Database reset complete"
    gleam run -m cigogne all
    @echo "✅ Migrations applied"

# Run any cigogne command not covered above
cigogne *args:
    gleam run -m cigogne {{args}}
