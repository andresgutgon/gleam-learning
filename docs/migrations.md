# Migrations with Cigogne and Just

This project uses [Cigogne](https://hex.pm/packages/cigogne/) for database migrations and [Just](https://github.com/casey/just) as a task runner to simplify common development workflows.

## Database Setup

A PostgreSQL database is managed via Docker Compose. See `docker-compose.yml` for service definitions.

The database includes the `pg_trgm` extension, enabled via an initialization script (`infra/initdb.sh`) that runs when the container first starts. This extension is necessary for efficient text searching with `ILIKE`.

## Running Migrations

All migration commands are defined in the `just/migrations.just` file.

### Prerequisites

1.  **Gleam installed**: Ensure Gleam is available (e.g., via `mise`).
2.  **Docker running**: The PostgreSQL container must be running. Use `docker compose up -d db` to start it.
3.  **`.env` file**: Ensure your `.env` file is present and contains the `DATABASE_URL` and other necessary environment variables for database connection. `just` automatically loads `.env` files.

### Common Commands

-   **Apply next migration**:
    ```bash
    just migrations up
    ```
    This runs the next pending migration.

-   **Roll back last migration**:
    ```bash
    just migrations down
    ```
    This rolls back the most recently applied migration.

-   **Apply all pending migrations**:
    ```bash
    just migrations last
    ```
    Applies all migrations that have not yet been applied to the database.

-   **Show migration status**:
    ```bash
    just migrations show
    ```
    Displays the status of applied migrations and the current schema.

-   **Create a new migration**:
    ```bash
    just migrations new <MigrationName>
    ```
    Generates a new SQL migration file with `up` and `down` sections.

-   **Run a specific Cigogne command**:
    ```bash
    just migrations cigogne <command>
    ```
    For any other Cigogne commands not directly mapped.

## Migration File Structure

Migration files are stored in `priv/migrations/` and follow the format
`<Timestamp>-<MigrationName>.sql`. Each file contains `--- migration:up` and
`--- migration:down` sections for applying and rolling back changes.

## Example

To apply all pending migrations:
```bash
just migrations up
```

To create a new migration named `add_users_table`:
```bash
just migrations new add_users_table
```
