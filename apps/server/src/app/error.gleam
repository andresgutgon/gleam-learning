pub type DatabaseError {
  UnexpectedNoRows
  RecordNotFound
  QueryFailed(String)
}
