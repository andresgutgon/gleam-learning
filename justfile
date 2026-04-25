set dotenv-load

mod migrations "just/migrations.just"

# List all recipes (default when running `just`)
default:
  @just --list --list-submodules
