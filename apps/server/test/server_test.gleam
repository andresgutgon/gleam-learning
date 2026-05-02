import gleeunit
import support/app/test_database

pub fn main() -> Nil {
  test_database.start()

  gleeunit.main()
}
