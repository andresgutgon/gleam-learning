set dotenv-load

mod migrations "just/migrations.just"
mod squirrel "just/squirrel.just"

default:
  @just --list --list-submodules

