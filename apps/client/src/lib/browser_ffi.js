if (typeof history !== "undefined") history.scrollRestoration = "manual";

export function window_location_origin() {
  return window.location.origin;
}

export function history_back() {
  window.history.back();
}

export function reload_page() {
  window.location.reload();
}

export function add_body_class(class_name) {
  document.body.classList.add(class_name);
}

export function save_scroll_to_history() {
  const state = { ...history.state, scrollTop: Math.round(window.scrollY) };
  history.replaceState(state, "", location.href);
}

export function read_scroll_from_history() {
  return history.state?.scrollTop ?? 0;
}

export function scroll_window_to(offset) {
  // Double RAF: modem's popstate handler schedules scrollTo(0,0) in a single
  // RAF. Nesting two RAFs ensures we fire in the frame after modem's, so our
  // restore wins.
  requestAnimationFrame(() => requestAnimationFrame(() => window.scrollTo(0, offset)));
}

export function mark_came_from_contacts() {
  const state = { ...history.state, cameFromContacts: true };
  history.replaceState(state, "", location.href);
}

export function check_came_from_contacts() {
  return !!history.state?.cameFromContacts;
}

const _sentinel_observers = new Map();

export function observe_sentinel(sentinel_id, callback) {
  requestAnimationFrame(() => {
    const existing = _sentinel_observers.get(sentinel_id);
    if (existing) {
      existing.disconnect();
      _sentinel_observers.delete(sentinel_id);
    }
    const el = document.getElementById(sentinel_id);
    if (!el) return;
    const observer = new IntersectionObserver(
      (entries) => {
        if (entries[0].isIntersecting) callback();
      },
      { rootMargin: "100px" },
    );
    observer.observe(el);
    _sentinel_observers.set(sentinel_id, observer);
  });
}

export function disconnect_sentinel(sentinel_id) {
  const observer = _sentinel_observers.get(sentinel_id);
  if (observer) {
    observer.disconnect();
    _sentinel_observers.delete(sentinel_id);
  }
}
