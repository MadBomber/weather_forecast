# ADR-0008: API Key Authentication via Environment Variables

## Status

Accepted

## Context

The API is completely open. Anyone can call it and exhaust the OpenWeatherMap API quota. An authentication mechanism is needed without introducing a database (ruled out by ADR-0005).

## Decision

Implement env-var based API key authentication in `ApplicationController`:

- Keys are stored in the `API_KEYS` environment variable as a comma-separated list.
- The `X-API-Key` request header is checked against the list on every request.
- **When `API_KEYS` is unset or empty, the API is open** — development and PoC mode require no configuration.
- The `/up` health-check endpoint is always public (no key required).

A rake task (`rake api_keys:generate`) generates cryptographically random keys.

## Consequences

### Positive

- Zero infrastructure — no database, no Redis for key storage.
- Keys can be rotated by updating the env var and restarting (or reloading).
- Simple to understand and audit.

### Negative

- No per-key revocation without restarting. If a key is compromised, the entire `API_KEYS` value must be updated.
- No per-key rate limiting (rate limiting remains IP-based from ADR-0009). Revisit when a database is introduced.
- All keys share the same permission level — no scopes.

## Future Considerations

When a database is introduced (future phase), migrate to Redis-backed API keys for revocation without restart, per-key rate limiting, and per-key analytics.

---

*Date*: 2026-03-20
*Author*: Development Team
