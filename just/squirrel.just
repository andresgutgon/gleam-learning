set working-directory := '../apps/server'

# Generate SQL squirrel
generate:
    mise exec -- gleam run -m squirrel

# Validates that the generated Gleam code is up-to-date with the SQL queries
check:
    mise exec -- gleam run -m squirrel check
