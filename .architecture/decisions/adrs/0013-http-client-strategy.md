# ADR-0013: HTTP Client Strategy — Net::HTTP with Fiber Scheduler

## Status

Accepted

## Context

Issue #25 requested replacing `Net::HTTP` with an async HTTP client (`async-http` or `httpx`) to improve concurrency. The concern was that synchronous `Net::HTTP` calls block the request thread while waiting for the external API response.

## Investigation

Under **Ruby 3.x** + **Falcon** (which requires the `io-event` gem), socket IO operations are automatically delegated to the fiber scheduler. This means:

- `Net::HTTP` calls yield the current fiber while waiting for the network
- Other fibers (handling other requests) continue to run during the wait
- The behavior is equivalent to using an explicit async HTTP client like `async-http`

This is documented in the Ruby 3.x scheduler interface (`Fiber::Scheduler`) and is a core feature of the `async`/`io-event` ecosystem that Falcon depends on.

Switching to `async-http` explicitly would:
- Break the existing VCR cassette infrastructure (VCR hooks WebMock, WebMock only intercepts `Net::HTTP`)
- Require rewriting all adapter tests without a clear benefit
- Introduce a new dependency that is already transitively present via Falcon

## Decision

Keep `Net::HTTP` as the HTTP client. Improve it with:

1. **Timeouts**: Use `Net::HTTP.start` with configurable `open_timeout` and `read_timeout` (defaulting to 5s and 10s respectively, configurable via `HTTP_OPEN_TIMEOUT` / `HTTP_READ_TIMEOUT` env vars).
2. **Connection reuse**: `Net::HTTP.start` with a block uses a persistent connection for the request duration (vs `Net::HTTP.get_response` which opens a new connection per call).
3. **Testability**: Extract `perform_get(uri)` as a standalone private method so it can be stubbed in isolation in unit tests.
4. **Error handling**: Rescue `Net::OpenTimeout`, `Net::ReadTimeout`, and connection errors explicitly and convert to `ApiError`.

## Consequences

### Positive

- No change to test infrastructure — VCR cassettes and WebMock stubs continue to work.
- Timeouts prevent hanging requests under poor network conditions.
- `perform_get` can be overridden in a subclass or swapped to `async-http` in the future if VCR gains async-http support.
- Net::HTTP is non-blocking under Falcon — same concurrency characteristics as async-http.

### Negative

- No HTTP/2 for outbound requests (OWM API supports HTTP/2 but Net::HTTP is HTTP/1.1 only).
- No connection pooling across requests (each request opens and closes its own connection, though `Net::HTTP.start` reuses within a single request).

### Future upgrade path

If HTTP/2 or persistent connection pooling across requests becomes important:

1. Add the `async-http` gem explicitly.
2. Replace `perform_get` with an `Async::HTTP::Internet` call.
3. Update tests to stub `perform_get` directly (already extracted) or use a VCR fork with async-http support.

---

*Date*: 2026-03-20
*Author*: Development Team
