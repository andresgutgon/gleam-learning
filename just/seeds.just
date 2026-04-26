# Seed database with test data

# Seed the database with 300 contacts
seed:
    gleam run -m packages/seeds

# Reset database and seed (drop, create, migrate, seed)
seed-reset:
    just migrations::reset
    gleam run -m packages/seeds
