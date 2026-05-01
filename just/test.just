set working-directory := '../apps/server'
set dotenv-filename := ".env.test"

# Setup test database
setup:
    createdb -h localhost -U gleam_learning_user gleam_learning_test || echo "Database already exists"
    psql -h localhost -U gleam_learning_user -d gleam_learning_test -c "CREATE EXTENSION IF NOT EXISTS pg_trgm;" || true
    just test _migrate

# Reset test database (drop, create, migrate)
reset:
    just test _teardown
    just test setup

[private]
_teardown:
    dropdb -h localhost -U gleam_learning_user gleam_learning_test || echo "Database doesn't exist"

[private]
_migrate:
    gleam run -m cigogne -- all
