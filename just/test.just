set working-directory := '..'
set dotenv-filename := ".env.test"

# Setup test database
setup:
    createdb gleam_learning_test || echo "Database already exists"
    psql -h localhost -U gleam_learning_user -d gleam_learning_test -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" || true
    just test _migrate

# Reset test database (drop, create, migrate)
reset:
    just test _teardown
    just test setup

# Teardown test database (internal use)
_teardown:
    dropdb gleam_learning_test || echo "Database doesn't exist"

# Run all pending migrations on test database (internal use)
_migrate:
    gleam run -m cigogne -- all
