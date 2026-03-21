# Contributing to WeatherForecast API

Thank you for your interest in contributing. This guide covers everything you need to get started.

## Table of Contents

- [Development Setup](#development-setup)
- [Running Tests](#running-tests)
- [Code Style](#code-style)
- [VCR Cassettes](#vcr-cassettes)
- [Debugging](#debugging)
- [Commit Messages](#commit-messages)
- [Pull Request Process](#pull-request-process)
- [Architecture Decision Records](#architecture-decision-records)

---

## Development Setup

### Prerequisites

- Ruby 4.0.2 (via rbenv, rvm, or mise)
- Redis 7+ running locally
- An [OpenWeatherMap API key](https://openweathermap.org/api) (free tier is sufficient)
- Bundler 2.5+

### Steps

```bash
git clone https://github.com/madbomber/weather_forecast.git
cd weather_forecast
bundle install
cp .env.example .env
# Edit .env — fill in OPENWEATHERMAP_API_KEY and SECRET_KEY_BASE
```

Generate `SECRET_KEY_BASE`:

```bash
bundle exec rails secret
```

### Starting the Server

```bash
bin/start.sh          # starts Falcon in background on port 3000
bin/stop.sh           # graceful stop
```

Or with Docker Compose (no local Ruby/Redis needed):

```bash
cp .env.example .env  # fill in your API key and secret key base
docker compose up
```

### Verify

```bash
curl http://localhost:3000/up
# => 200 OK
curl "http://localhost:3000/api/v1/current?location=London"
```

### Optional: Generate an API Key

If you want to run with `API_KEYS` set:

```bash
bundle exec rake api_keys:generate
# Copy the key into .env as: API_KEYS=<key>
```

---

## Running Tests

```bash
# Full suite (includes coverage report via SimpleCov)
bundle exec rspec

# Single file
bundle exec rspec spec/services/weather/open_weather_map_adapter_spec.rb

# Single example by line number
bundle exec rspec spec/models/weather/temperature_spec.rb:42

# Open coverage report after a run
open coverage/index.html
```

The test suite enforces **80% minimum overall coverage** and **60% minimum per-file coverage** (configured in `spec/spec_helper.rb`). A failing coverage threshold fails the build.

### Test Layout

| Path | What it covers |
|------|---------------|
| `spec/models/` | Value objects (`Temperature`, `Forecast`) |
| `spec/services/` | Adapter unit tests (WebMock) + VCR replay tests |
| `spec/requests/api/v1/` | Controller / endpoint integration tests |
| `spec/requests/authentication_spec.rb` | API key auth edge cases |
| `spec/requests/cors_spec.rb` | CORS preflight and origin checks |
| `spec/requests/rate_limiting_spec.rb` | Rack::Attack throttle behaviour |

---

## Code Style

We use RuboCop with the Rails Omakase ruleset:

```bash
bundle exec rubocop           # check
bundle exec rubocop -a        # auto-fix safe offenses
bundle exec rubocop -A        # auto-fix all offenses (review diff carefully)
```

Run `bundle exec brakeman` before opening a PR to catch security issues.

### Key conventions

- **Debugging**: always use `debug_me`, never `puts`. The gem comes from <https://github.com/madbomber/debug_me>.
  ```ruby
  debug_me { [:location, :temperature] }   # inspect variables
  debug_me "Fetching #{location}"           # string message
  ```
- **Method isolation**: every method — public or private — must be easily tested in isolation. Avoid coupling methods to global state.
- **No database**: this project has no ActiveRecord models backed by a database (ADR-0005). Redis is the only persistence layer.
- **Adapter pattern**: new weather providers inherit from `Weather::BaseAdapter`. Do not add provider logic directly to controllers or services outside the adapter hierarchy.

---

## VCR Cassettes

External HTTP calls in tests are recorded with [VCR](https://github.com/vcr/vcr) and replayed from YAML cassettes stored in `spec/fixtures/vcr_cassettes/`.

### Playing back existing cassettes

No extra setup needed — cassettes are committed to the repo and replayed automatically. The `record: :none` default means tests never hit the real API unless a cassette is missing.

### Recording a new cassette

1. Ensure `OPENWEATHERMAP_API_KEY` is set in your environment.
2. Change `record: :none` to `record: :new_episodes` for that spec (or `:all` to re-record).
3. Run the spec — VCR will make the real HTTP call and write the cassette.
4. Restore `record: :none` (or remove the override to use the default).
5. Commit the cassette file.

```ruby
# Example VCR spec
RSpec.describe Weather::OpenWeatherMapAdapter, :vcr do
  # uses cassette name derived from example description automatically
  # OR
  it "fetches current weather", vcr: { cassette_name: "openweathermap/current_weather_by_city" } do
    result = adapter.current_weather(location: "London")
    expect(result).to be_a(Weather::Forecast)
  end
end
```

### Cassette format notes

- `recorded_at` must use RFC 2616 format: `'Mon, 13 Oct 2025 18:00:00 GMT'`
- API keys are filtered automatically (`<OWM_API_KEY>` placeholder in cassettes).
- Requests are matched on method, host, and path (query string ignored).

---

## Debugging

Use `debug_me` from the [`debug_me` gem](https://github.com/madbomber/debug_me) for all debug output:

```ruby
# ✅ Correct
debug_me { [:location, :cache_key, :result] }
debug_me "About to call OWM API"

# ❌ Never do this
puts "location: #{location}"
```

`debug_me` writes structured output to STDOUT and is stripped from production by convention. Remove all `debug_me` calls before opening a PR.

---

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/). The full spec is in `COMMITS.md`.

```
<type>(<scope>): <short description>

[optional body]

[optional footer]
```

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `build`, `ci`, `chore`

**Scopes**: `weather`, `adapter`, `cache`, `api`, `models`, `services`, `tests`, `docs`, `adr`

**Examples:**

```
feat(adapter): add NWS weather adapter for US locations
fix(cache): use correct TTL env var for current weather
docs(readme): fix endpoint URL examples
test(auth): add spec for invalid API key response
```

---

## Pull Request Process

1. **Branch** from `develop`:
   ```bash
   git checkout -b feat/my-feature develop
   ```

2. **Write tests first** — ensure coverage doesn't drop below 80%.

3. **Run the full checklist before pushing**:
   ```bash
   bundle exec rspec              # all tests pass
   bundle exec rubocop            # no style violations
   bundle exec brakeman           # no security warnings
   ```

4. **Open a PR against `develop`** with:
   - A clear description of the change and motivation
   - Reference to any related issue (`Closes #N`)
   - Notes on any ADR that was consulted or should be created

5. **Architectural changes** — if your PR changes caching strategy, provider selection, authentication, or middleware configuration, create an ADR in `.architecture/decisions/adrs/` before or alongside your code.

---

## Architecture Decision Records

Significant decisions are documented as ADRs in `.architecture/decisions/adrs/`. Before making a change that touches:

- Caching strategy or Redis configuration
- Web server or middleware
- Weather provider selection
- Authentication or security policy

…check whether an existing ADR covers it. If your change contradicts an ADR, discuss it in the PR or create a superseding ADR.

New ADRs follow the naming convention `NNNN-kebab-case-title.md` and include Status, Context, Decision, and Consequences sections.
