set dotenv-load

mod migrations "just/migrations.just"
mod squirrel "just/squirrel.just"
mod seeds "just/seeds.just"
mod test "just/test.just"

default:
  @just --list --list-submodules

