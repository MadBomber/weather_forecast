# ADR-0011: Centralized Error Handling in ApplicationController

## Status

Accepted

## Context

The initial implementation placed identical `rescue` blocks in every controller action — four rescue clauses repeated in both `#current` and `#forecast`. This violated DRY and meant any change to error format required touching every action. Additionally, unmatched routes returned Rails' default HTML error page, breaking the API-only contract.

## Decision

1. Move all `rescue_from` handlers to `ApplicationController` so they apply to every action automatically.
2. Add a catch-all route (`match "*path"`) that returns a JSON 404 for unknown paths.
3. Keep the error response format as `{ error: "..." }` — simple, consistent, and understood by existing clients.

## Consequences

### Positive

- Error handling is defined once and inherited by all controllers.
- All error responses are JSON — the HTML bleed-through for 404/500 on unknown routes is eliminated.
- Adding a new adapter error type requires one change in `ApplicationController`, not N changes across N controllers.

### Negative

- `rescue_from StandardError` in `ApplicationController` is a broad catch-all; any unhandled exception anywhere in the stack returns 500. This is intentional but means debugging requires log inspection rather than stack traces surfacing to the client.

## References

- RFC 7807 (Problem Details) was considered for error format but rejected in favour of the simpler `{error}` key already understood by API consumers.

---

*Date*: 2026-03-20
*Author*: Development Team
