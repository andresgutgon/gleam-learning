# Seed database with test data

# Seed the database with 300 contacts
seed:
    gleam run -m packages/seeds

# TODO: Reset database and seed (drop, create, migrate, seed)
# Requires db-reset command to be implemented
seed-reset:
    @echo "TODO: Implement db-reset command (drop DB, create DB, apply migrations)"
    @echo "For now, run: just migrations::last && just seeds::seed"
    gleam run -m packages/seeds
