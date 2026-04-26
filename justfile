set dotenv-load

mod migrations "just/migrations.just"
mod squirrel "just/squirrel.just"
mod seeds "just/seeds.just"

default:
  @just --list --list-submodules

