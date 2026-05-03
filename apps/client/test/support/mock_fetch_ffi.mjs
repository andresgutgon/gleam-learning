const originalFetch = globalThis.fetch;
let lastRequestUrl = "";

export function setupMockFetch(status, jsonBody) {
  if (!globalThis.window) {
    globalThis.window = { location: { origin: "http://localhost" } };
  }
  globalThis.fetch = async (request) => {
    lastRequestUrl = request.url;
    return {
      status,
      headers: new Headers({ "content-type": "application/json" }),
      json: async () => JSON.parse(jsonBody),
    };
  };
}

export function teardownMockFetch() {
  globalThis.fetch = originalFetch;
  lastRequestUrl = "";
}

export function getLastRequestUrl() {
  return lastRequestUrl;
}
