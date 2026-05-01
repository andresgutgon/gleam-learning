set working-directory := '../apps/server'

# Seed the database with 300 contacts
seed:
    gleam run -m seeds

# Reset database and seed (drop, create, migrate, seed)
seed-reset:
    just migrations::reset
    gleam run -m seeds
