# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive architecture review document (`architecture_review.md`) covering 12 major areas with detailed findings and prioritized recommendations
- Performance metrics to forecast endpoint (cached status and duration_ms tracking)
- Utility script `bin/flush_cache.sh` for Redis cache management
- Utility script `bin/weather.sh` for CLI-based weather data queries with pretty-print JSON
- Utility scripts `bin/start.sh` and `bin/stop.sh` for server management
- Comprehensive utility scripts documentation in README.md
- dotenv-rails gem for automatic `.env.local` file loading

### Changed
- Forecast endpoint response format now includes `data` and `performance` keys for consistency
- Enhanced `bin/weather.sh` with JSON pretty-printing using `jq`

## [0.2.0] - 2025-10-13

### Added
- Comprehensive RSpec test suite with 43 passing tests ([PR #10](https://github.com/MadBomber/weather_forecast/pull/10))
  - Request specs for API endpoints (`spec/requests/api/v1/weather_spec.rb`)
  - Model specs for Forecast and Temperature value objects
  - Service specs for OpenWeatherMapAdapter with WebMock stubbing
  - Test coverage for error handling (404, 429, 401, 500)
  - Test coverage for multiple location formats (city, zip, coordinates)
  - Test coverage for caching behavior

### Changed
- Cache TTL for current weather updated from 15 minutes to 30 minutes to align with project requirements ([PR #10](https://github.com/MadBomber/weather_forecast/pull/10))

### Fixed
- Test suite configuration for API-only Rails application (disabled ActiveRecord)

## [0.1.0] - 2025-10-13

### Added
- Weather API implementation with OpenWeatherMap integration ([PR #9](https://github.com/MadBomber/weather_forecast/pull/9))
  - RESTful API endpoints: `GET /api/v1/current` and `GET /api/v1/forecast`
  - Weather controller with parameter validation and error handling
  - OpenWeatherMapAdapter service for external API integration
  - BaseAdapter interface for extensible weather service integrations
  - Weather models: Forecast and Temperature value objects
  - Redis caching with configurable TTL (15min current, 30min forecast)
  - Support for multiple location formats (city names, zip codes, coordinates)
  - Temperature conversions (Celsius, Fahrenheit, Kelvin)
  - Wind direction conversion (degrees to cardinal directions)
  - Precipitation chance estimation
  - Comprehensive error handling (LocationNotFoundError, ApiError, RateLimitError)
- Environment variable template `.env.example` ([PR #8](https://github.com/MadBomber/weather_forecast/pull/8))
  - OpenWeatherMap API configuration
  - Redis configuration with TTL settings
  - Rails configuration (environment, secret key)
  - Production and development settings
  - Detailed comments and setup instructions
- Project requirements documentation (`requirements.md`) ([PR #8](https://github.com/MadBomber/weather_forecast/pull/8))

### Changed
- GitHub Actions workflow updated to use `actions/checkout@v5` (Node 24 support) ([PR #1](https://github.com/MadBomber/weather_forecast/pull/1))

## [0.0.1] - 2025-10-10

### Added
- Initial Rails 8.0.3 API-only application setup
- Project context documentation (`docs/architecture/PROJECT_CONTEXT.md`)
- Architecture Decision Records (ADRs):
  - ADR-001: Rails 8 adoption
  - ADR-002: API-only mode
  - ADR-003: Service layer architecture
  - ADR-004: Caching strategy
  - ADR-005: OpenWeatherMap integration
  - ADR-006: Falcon async server
  - ADR-007: Repository pattern removed
- Development tooling:
  - RuboCop Rails with Omakase style guide
  - Brakeman security scanner
  - GitHub Actions CI workflow
  - `.gitignore` configuration
- Dependencies:
  - `falcon-rails` for async HTTP server
  - `redis` for caching
  - `openweathermap` gem for API integration
  - `debug_me` for debugging (development/test)
  - `rspec-rails` and `webmock` for testing
- README.md with comprehensive setup and usage documentation

---

## Legend

### Change Types
- **Added** - New features
- **Changed** - Changes to existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security vulnerability fixes

### Version Numbering
This project uses [Semantic Versioning](https://semver.org/):
- **MAJOR** version for incompatible API changes
- **MINOR** version for backwards-compatible functionality additions
- **PATCH** version for backwards-compatible bug fixes

---

## Links

- [Repository](https://github.com/MadBomber/weather_forecast)
- [Issues](https://github.com/MadBomber/weather_forecast/issues)
- [Pull Requests](https://github.com/MadBomber/weather_forecast/pulls)
