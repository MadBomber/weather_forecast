# ADR-0012: Docker Compose for Development Environment

## Status

Accepted

## Context

The existing `Dockerfile` targets production (Rails + Thruster/Falcon on port 80). Developers must manually start Redis and configure environment variables, creating inconsistent setups.

## Decision

Add `docker-compose.yml` to orchestrate the full development stack:

- **`web`** service: builds from the production `Dockerfile`, maps port 3000→80, reads credentials from `.env` file, overrides `REDIS_URL` to use the compose Redis service.
- **`redis`** service: `redis:7-alpine` with healthcheck; `web` waits until Redis is healthy before starting.

A `.env.example` file documents all environment variables. Developers copy it to `.env` and fill in their API key before running `docker compose up`.

## Usage

```bash
cp .env.example .env
# Edit .env — add OPENWEATHERMAP_API_KEY and SECRET_KEY_BASE
docker compose up
curl http://localhost:3000/api/v1/current?location=London
```

## Consequences

### Positive

- Single command to start the full stack.
- Redis and app always start together in the correct order.
- Eliminates "works on my machine" issues from Redis version differences.

### Negative

- Uses the production `Dockerfile` — no live code reload. For iterative development, running `bundle exec rails s` locally remains faster.
- Requires Docker Desktop or equivalent on the developer's machine.

---

*Date*: 2026-03-20
*Author*: Development Team
