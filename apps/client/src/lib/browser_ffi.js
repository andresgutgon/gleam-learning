if (typeof history !== "undefined") history.scrollRestoration = "manual";

// View Transitions + Lustre interop: during a view transition's DOM update
// phase, the browser pauses paint and `requestAnimationFrame` callbacks don't
// fire. Lustre's renderer schedules via rAF, so the DOM never updates inside
// the update callback and the transition times out. Workaround: while a VT is
// in flight, redirect rAF to queueMicrotask. Microtasks DO fire during the DOM
// update phase, so Lustre renders and the new snapshot reflects the new page.
let _vtRafAsMicrotask = false;
const _origRAF = window.requestAnimationFrame.bind(window);
window.requestAnimationFrame = function (cb) {
  if (_vtRafAsMicrotask) {
    queueMicrotask(() => cb(performance.now()));
    return 0;
  }
  return _origRAF(cb);
};

// Forward navigation: set the rAF-patch flag in the capture phase so it's
// true BEFORE Lustre's click handler dispatches (so its scheduleRender uses
// the patched rAF too). Back is handled via the popstate listener below
// instead, so it works for both the back-button click AND the macOS trackpad
// swipe gesture (which fires popstate directly without a click).
document.addEventListener(
  "click",
  (e) => {
    const t = e.target;
    if (!t || !t.closest) return;
    if (t.closest("[data-contact-id]")) {
      _vtRafAsMicrotask = true;
      // Safety net in case no view transition runs.
      setTimeout(() => {
        _vtRafAsMicrotask = false;
      }, 1000);
    }
  },
  true,
);

// Track the URL we're navigating away from so the popstate handler below
// knows whether we're going back from a contact detail page.
let _prevUrl = typeof window !== "undefined" ? window.location.href : "";
const _detailPathRe = /^\/contacts\/(\d+)$/;

// Lock the document scroll when the detail overlay is mounted. Without this,
// wheel/trackpad scrolling propagates to the contacts list behind the
// overlay, the virtualizer's scroll_offset gets rewritten by the window
// scroll listener, and the back transition lands on the wrong rows.
function update_scroll_lock() {
  const onDetail = _detailPathRe.test(window.location.pathname);
  document.documentElement.classList.toggle("scroll-locked", onDetail);
}
if (typeof window !== "undefined") {
  // Initial state (e.g. direct-load to a detail URL).
  update_scroll_lock();
  // Any navigation — real popstate, our synthetic one, modem.push/replace —
  // can change the URL and therefore the lock state.
  window.addEventListener("popstate", update_scroll_lock);
  window.addEventListener("modem-push", update_scroll_lock);
  window.addEventListener("modem-replace", update_scroll_lock);
}

// Capture-phase popstate handler. Wraps contacts ↔ contact-detail
// navigations (back button click, trackpad swipe, browser back/forward,
// keyboard) in a view transition. Re-dispatching a synthetic popstate inside
// the VT callback lets modem's normal route-change flow run — just inside
// the transition. The `_inSyntheticPopstate` guard prevents re-entry both
// from that synthetic dispatch and from the click-based forward path
// (`navigate_with_view_transition`, which also synthesizes popstate).
//
// Wrapping BOTH directions is what preserves the contacts scroll: otherwise
// modem's `scrollTo(0, 0)` on forward-swipe lets the window scroll listener
// reset the virtualizer's scroll_offset to 0, so on the next back the list
// renders from the top.
let _inSyntheticPopstate = false;
const _isContactsPath = (p) => p === "/contacts" || p === "/";

function vt_forward(contact_id) {
  clear_row_vt_names();
  tag_row(contact_id);

  _vtRafAsMicrotask = true;
  const savedScroll = window.scrollY;

  document
    .startViewTransition(() => {
      return new Promise((resolve) => {
        _inSyntheticPopstate = true;
        window.dispatchEvent(new PopStateEvent("popstate"));
        _inSyntheticPopstate = false;

        requestAnimationFrame(() => {
          if (window.scrollY !== savedScroll) {
            window.scrollTo(0, savedScroll);
          }
          // Detail overlay is now in DOM with its own vt-names; clear the
          // row's so NEW has one element per name.
          clear_row_vt_names();
          requestAnimationFrame(resolve);
        });
      });
    })
    .finished.catch(() => {})
    .finally(() => {
      _vtRafAsMicrotask = false;
    });
}

function vt_back(contact_id) {
  _vtRafAsMicrotask = true;
  const savedScroll = window.scrollY;

  document
    .startViewTransition(() => {
      return new Promise((resolve) => {
        _inSyntheticPopstate = true;
        window.dispatchEvent(new PopStateEvent("popstate"));
        _inSyntheticPopstate = false;

        requestAnimationFrame(() => {
          if (window.scrollY !== savedScroll) {
            window.scrollTo(0, savedScroll);
          }
          // Detail overlay has been removed; tag the row we're returning
          // to so it morphs back from the detail header position.
          clear_row_vt_names();
          tag_row(contact_id);
          requestAnimationFrame(resolve);
        });
      });
    })
    .finished.catch(() => {})
    .finally(() => {
      _vtRafAsMicrotask = false;
      clear_row_vt_names();
    });
}

window.addEventListener(
  "popstate",
  (e) => {
    if (_inSyntheticPopstate) {
      // Still keep _prevUrl in sync even when we skip the handler.
      _prevUrl = window.location.href;
      return;
    }
    const newUrl = window.location.href;
    const oldUrl = _prevUrl;
    _prevUrl = newUrl;

    if (typeof document.startViewTransition !== "function") return;

    const oldPath = (() => {
      try {
        return new URL(oldUrl).pathname;
      } catch {
        return "";
      }
    })();
    const newPath = new URL(newUrl).pathname;

    const fromDetail = oldPath.match(_detailPathRe);
    const toDetail = newPath.match(_detailPathRe);

    if (fromDetail && _isContactsPath(newPath)) {
      e.stopImmediatePropagation();
      vt_back(parseInt(fromDetail[1], 10));
    } else if (_isContactsPath(oldPath) && toDetail) {
      e.stopImmediatePropagation();
      vt_forward(parseInt(toDetail[1], 10));
    }
  },
  true,
);


export function window_location_origin() {
  return window.location.origin;
}

export function window_inner_height() {
  return window.innerHeight;
}

export function debug_log(label, value) {
  console.log("[gleam-debug]", label, value);
  return null;
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
  requestAnimationFrame(() =>
    requestAnimationFrame(() => window.scrollTo(0, offset)),
  );
}

export function mark_came_from_contacts() {
  const state = { ...history.state, cameFromContacts: true };
  history.replaceState(state, "", location.href);
}

export function check_came_from_contacts() {
  return !!history.state?.cameFromContacts;
}

// The virtualizer pools row DOM nodes, so a `view-transition-name` set via
// inline style on one slot can linger on the node when that slot is later
// repurposed for a different contact. Two elements with the same vt-name in a
// snapshot triggers `InvalidStateError`. Clear before setting and on cleanup.
function clear_row_vt_names() {
  document
    .querySelectorAll(
      ".vt-contact-name, .vt-contact-stage, .vt-contact-email",
    )
    .forEach((el) => {
      el.style.viewTransitionName = "";
    });
}

function tag_row(contact_id) {
  const row = document.querySelector(`[data-contact-id="${contact_id}"]`);
  if (!row) return;
  const name = row.querySelector(".vt-contact-name");
  const stage = row.querySelector(".vt-contact-stage");
  const email = row.querySelector(".vt-contact-email");
  if (name) name.style.viewTransitionName = "contact-name";
  if (stage) stage.style.viewTransitionName = "contact-stage";
  if (email) email.style.viewTransitionName = "contact-email";
}

export function navigate_with_view_transition(contact_id, path, then_fn) {
  clear_row_vt_names();
  tag_row(contact_id);

  const doNavigate = () => {
    window.history.pushState({}, "", path);
    // Guard against our own popstate handler re-wrapping this navigation.
    _inSyntheticPopstate = true;
    window.dispatchEvent(new PopStateEvent("popstate"));
    _inSyntheticPopstate = false;
    then_fn();
  };

  if (!document.startViewTransition) {
    doNavigate();
    return;
  }

  // Preserve document scroll across the transition. modem's popstate handler
  // scrolls to 0 on every nav; with the overlay model, we want contacts to
  // keep its scroll position so it's right where the user left it on back.
  const savedScroll = window.scrollY;

  document
    .startViewTransition(() => {
      doNavigate();
      return new Promise((resolve) => {
        requestAnimationFrame(() => {
          if (window.scrollY !== savedScroll) {
            window.scrollTo(0, savedScroll);
          }
          clear_row_vt_names();
          requestAnimationFrame(resolve);
        });
      });
    })
    .finished.catch(() => {})
    .finally(() => {
      _vtRafAsMicrotask = false;
    });
}

export function navigate_back_with_view_transition(contact_id) {
  if (!document.startViewTransition) {
    window.history.back();
    return;
  }

  // Preserve document scroll: contacts has been mounted underneath the detail
  // overlay throughout, so window.scrollY is already at the right place. We
  // just need to undo modem's popstate-driven scrollTo(0,0).
  const savedScroll = window.scrollY;

  document
    .startViewTransition(() => {
      return new Promise((resolve) => {
        window.addEventListener(
          "popstate",
          () => {
            // After popstate, the router flips to ContactsPage, Lustre
            // re-renders, and the detail overlay is removed from DOM. One
            // patched-rAF tick lets that render land before we tag the
            // matching row (which has been in the DOM the whole time, just
            // hidden under the overlay).
            requestAnimationFrame(() => {
              if (window.scrollY !== savedScroll) {
                window.scrollTo(0, savedScroll);
              }
              clear_row_vt_names();
              const nameEl = document.querySelector(
                `[data-contact-id="${contact_id}"] .vt-contact-name`,
              );
              const stageEl = document.querySelector(
                `[data-contact-id="${contact_id}"] .vt-contact-stage`,
              );
              if (nameEl) nameEl.style.viewTransitionName = "contact-name";
              if (stageEl) stageEl.style.viewTransitionName = "contact-stage";
              requestAnimationFrame(resolve);
            });
          },
          { once: true },
        );
        window.history.back();
      });
    })
    .finished.catch(() => {})
    .finally(() => {
      _vtRafAsMicrotask = false;
      clear_row_vt_names();
    });
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
