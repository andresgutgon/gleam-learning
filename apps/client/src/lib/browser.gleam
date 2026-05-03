@external(javascript, "./browser_ffi.js", "window_location_origin")
pub fn window_location_origin() -> String

@external(javascript, "./browser_ffi.js", "history_back")
pub fn history_back() -> Nil

@external(javascript, "./browser_ffi.js", "reload_page")
pub fn reload_page() -> Nil

@external(javascript, "./browser_ffi.js", "add_body_class")
pub fn add_body_class(class_name: String) -> Nil

@external(javascript, "./browser_ffi.js", "observe_sentinel")
pub fn observe_sentinel(sentinel_id: String, callback: fn() -> Nil) -> Nil

@external(javascript, "./browser_ffi.js", "disconnect_sentinel")
pub fn disconnect_sentinel(sentinel_id: String) -> Nil

@external(javascript, "./browser_ffi.js", "save_scroll_to_history")
pub fn save_scroll_to_history() -> Nil

@external(javascript, "./browser_ffi.js", "read_scroll_from_history")
pub fn read_scroll_from_history() -> Int

@external(javascript, "./browser_ffi.js", "scroll_window_to")
pub fn scroll_window_to(offset: Int) -> Nil

@external(javascript, "./browser_ffi.js", "mark_came_from_contacts")
pub fn mark_came_from_contacts() -> Nil

@external(javascript, "./browser_ffi.js", "check_came_from_contacts")
pub fn check_came_from_contacts() -> Bool
