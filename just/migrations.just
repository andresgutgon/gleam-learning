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

# Run any cigogne command not covered above
cigogne *args:
    gleam run -m cigogne {{args}}
