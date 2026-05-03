@external(javascript, "./mock_fetch_ffi.mjs", "setupMockFetch")
pub fn setup(status: Int, json_body: String) -> Nil

@external(javascript, "./mock_fetch_ffi.mjs", "teardownMockFetch")
pub fn teardown() -> Nil

@external(javascript, "./mock_fetch_ffi.mjs", "getLastRequestUrl")
pub fn last_request_url() -> String
