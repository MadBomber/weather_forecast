# ADR-0009: Rate Limiting with Rack::Attack

## Status

Accepted

## Context

The API has no rate limiting. A single client can exhaust the OpenWeatherMap API quota or perform a DoS attack by issuing unlimited requests. Redis is already in the stack.

## Decision

Use `rack-attack` gem for IP-based rate limiting with two tiers:

1. **Sustained**: 60 requests/minute per IP — prevents quota exhaustion.
2. **Burst**: 10 requests/10 seconds per IP — prevents rapid-fire flooding.

`Rack::Attack` reuses the existing `Rails.cache` (Redis), so no additional infrastructure is required. Limits are configurable via `RATE_LIMIT_API_RPM` and `RATE_LIMIT_BURST_RPS` environment variables.

Throttled responses return JSON `{ error: ..., retry_after: N }` with a `Retry-After` header.

## Consequences

### Positive

- Protects OpenWeatherMap API quota.
- Configurable limits without code changes.
- Uses existing Redis — no new dependency infrastructure.

### Negative

- IP-based throttling can affect shared NAT users (multiple clients behind one IP). Acceptable for a PoC; revisit with per-API-key throttling when #12 is implemented.

## References

- [Rack::Attack documentation](https://github.com/rack/rack-attack)

---

*Date*: 2026-03-20
*Author*: Development Team
