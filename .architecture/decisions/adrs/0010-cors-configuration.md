# ADR-0010: CORS Configuration with rack-cors

## Status

Accepted

## Context

The Weather Forecast API needs to be consumable by web applications running on different domains. Without CORS headers, browser-based clients receive a CORS error before any request reaches the server.

## Decision

Use the `rack-cors` gem to configure CORS at the Rack middleware layer. Configuration:

- **Default policy**: Allow all origins (`*`) — appropriate for a public read-only GET API with no user-specific data.
- **Restricted methods**: Only `GET` and `OPTIONS` — this API has no write operations.
- **Production restriction**: Override with `CORS_ALLOWED_ORIGINS=https://domain.com` env var to limit to specific origins.
- **Preflight cache**: `max_age: 600` (10 minutes) reduces OPTIONS round-trips.

## Consequences

### Positive

- Any web application can call the API out of the box (useful for PoC and demos).
- Production environments can be locked down via environment variable without code changes.
- Only safe HTTP methods are exposed.

### Negative

- Default open policy means any site can proxy-bypass via browser if desired. Acceptable since the API is public and read-only.

## References

- [rack-cors gem](https://github.com/cyu/rack-cors)
- [MDN CORS documentation](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS)

---

*Date*: 2026-03-20
*Author*: Development Team
