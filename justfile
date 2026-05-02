set dotenv-load

mod dev "just/dev.just"
mod migrations "just/migrations.just"
mod squirrel "just/squirrel.just"
mod seeds "just/seeds.just"
mod test "just/test.just"
mod docker "just/docker/docker.just"

default:
  @just --list --list-submodules

