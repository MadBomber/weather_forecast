# WeatherForecast API - AI Coding Assistant Context

This file provides context to AI coding assistants (Claude Code, Cursor, GitHub Copilot) working on the WeatherForecast Rails API project.

## Project Overview

**Name**: WeatherForecast API
**Type**: Ruby on Rails 8 API-only application
**Purpose**: Integration layer for third-party weather data providers, exposing unified weather conditions and forecast data through a RESTful API

**Key Focus**: This application serves as an aggregation and normalization layer for multiple weather data sources (National Weather Service, OpenWeatherMap), providing a consistent API interface regardless of the underlying provider.

## Technology Stack

### Core
- **Language**: Ruby 3.4.6
- **Framework**: Rails 8.0.3 (API-only mode)
- **Web Server**: Falcon (HTTP/2 support via falcon-rails)
- **Database**: SQLite (development), configurable for production
- **Cache/Sessions**: Redis 5.4.1

### Key Gems
- `redis` - Redis client for caching and Action Cable
- `falcon-rails` - High-performance HTTP/2 server
- `nws_openapi_sdk` - National Weather Service API integration
- `openweathermap` - OpenWeatherMap API integration
- `claude-on-rails` - AI assistance tools
- `debug_me` - Debugging output (ALWAYS use instead of puts)
- `brakeman` - Security analysis
- `rspec-rails` - Testing framework

### Rails 8 Features
- Solid Cache (available but using Redis)
- Solid Queue (for background jobs)
- Solid Cable (available but using Redis)

## Architecture

### Principles
Refer to `.architecture/principles.md` for full details. Key principles:
1. API-First Design
2. Performance Through Caching
3. Testable by Design (every method must be easily tested in isolation)
4. Use debug_me for debugging (NEVER use puts)
5. Domain-Driven Design
6. Rails Conventions Over Configuration

### Architecture Documentation
- **Decisions**: `.architecture/decisions/adrs/` - Architectural Decision Records
- **Principles**: `.architecture/principles.md` - Core architectural principles
- **Team**: `.architecture/members.yml` - Architecture review team members
- **Reviews**: `.architecture/reviews/` - Architecture review documents

## Coding Standards

### Ruby Style
- Follow Rubocop rules (see `.rubocop.yml`)
- Use Ruby 3.4 features and idioms
- Prefer functional patterns where appropriate
- Keep methods focused and single-purpose

### Debugging
**CRITICAL**: Never use `puts` for debugging. Always use the `debug_me` gem:

```ruby
# Simple string output
debug_me "Processing forecast request"

# Inspecting variables
debug_me { [ :location, :forecast_data ] }
```

### Testing
- Use RSpec for all tests
- Every method MUST be easily tested in isolation
- Use dependency injection where appropriate
- Mock external services in tests
- Maintain high test coverage
- Tests should describe behavior, not implementation

### Rails Patterns
- Follow RESTful conventions for API endpoints
- Use service objects for complex business logic
- Use value objects for domain concepts (Temperature, WindSpeed, etc.)
- Keep controllers thin (delegate to services)
- Use concerns for shared behavior

### Naming Conventions
- Controllers: Plural nouns (`ForecastsController`)
- Models: Singular nouns (`Forecast`)
- Services: Verb + noun (`FetchWeatherData`)
- Value Objects: Domain concepts (`Temperature`, `WeatherCondition`)
- Tests: Describe behavior (`describe '#fetch_forecast'`)

## Directory Structure

```
app/
├── controllers/      # API endpoints
│   └── api/         # API versioned endpoints
│       └── v1/
├── models/          # Domain models
├── services/        # Business logic services
├── jobs/            # Background jobs
└── channels/        # Action Cable channels

spec/
├── controllers/     # Controller specs
├── models/         # Model specs
├── services/       # Service specs
└── support/        # Test helpers

.architecture/       # Architecture documentation
├── decisions/      # ADRs
├── principles.md   # Architectural principles
└── members.yml     # Review team

config/
├── routes.rb       # API routes
├── cable.yml       # Redis Action Cable config
└── environments/   # Environment configs
```

## Common Patterns

### Creating a Service Object
```ruby
# app/services/fetch_weather_forecast.rb
class FetchWeatherForecast
  def initialize(location:, api_client: WeatherApiClient.new)
    @location = location
    @api_client = api_client
  end

  def call
    debug_me "Fetching forecast for location: #{@location}"

    cached_data = fetch_from_cache
    return cached_data if cached_data

    fetch_and_cache_from_api
  end

  private

  def fetch_from_cache
    Rails.cache.read(cache_key)
  end

  def fetch_and_cache_from_api
    data = @api_client.fetch(@location)
    Rails.cache.write(cache_key, data, expires_in: 1.hour)
    data
  end

  def cache_key
    "forecast:#{@location}:#{Time.current.to_i / 3600}"
  end
end
```

### Creating a Value Object
```ruby
# app/models/temperature.rb
class Temperature
  include Comparable

  attr_reader :celsius

  def initialize(celsius:)
    @celsius = celsius.to_f
  end

  def fahrenheit
    (celsius * 9.0 / 5.0) + 32.0
  end

  def <=>(other)
    celsius <=> other.celsius
  end

  def to_s
    "#{celsius}°C (#{fahrenheit.round(1)}°F)"
  end
end
```

### API Controller
```ruby
# app/controllers/api/v1/forecasts_controller.rb
module Api
  module V1
    class ForecastsController < ApplicationController
      def show
        debug_me { [:location_param] }

        forecast = FetchWeatherForecast.new(location: location_param).call

        render json: forecast, status: :ok
      rescue WeatherApiClient::LocationNotFound
        render json: { error: 'Location not found' }, status: :not_found
      end

      private

      def location_param
        params.require(:location)
      end
    end
  end
end
```

## Testing Patterns

### RSpec Service Spec
```ruby
# spec/services/fetch_weather_forecast_spec.rb
require 'rails_helper'

RSpec.describe FetchWeatherForecast do
  describe '#call' do
    let(:location) { 'New York' }
    let(:api_client) { instance_double(WeatherApiClient) }
    let(:service) { described_class.new(location: location, api_client: api_client) }

    context 'when data is cached' do
      before do
        Rails.cache.write("forecast:#{location}:#{Time.current.to_i / 3600}", cached_data)
      end

      let(:cached_data) { { temperature: 72, condition: 'sunny' } }

      it 'returns cached data without calling API' do
        expect(api_client).not_to receive(:fetch)
        expect(service.call).to eq(cached_data)
      end
    end

    context 'when data is not cached' do
      let(:api_data) { { temperature: 68, condition: 'cloudy' } }

      before do
        allow(api_client).to receive(:fetch).with(location).and_return(api_data)
      end

      it 'fetches from API and caches the result' do
        expect(service.call).to eq(api_data)
        expect(Rails.cache.read("forecast:#{location}:#{Time.current.to_i / 3600}")).to eq(api_data)
      end
    end
  end
end
```

## Environment Configuration

### Development
- Redis: `redis://localhost:6379/0` (cache), `redis://localhost:6379/1` (cable)
- Database: SQLite (`db/development.sqlite3`)
- Cache: Enabled via Redis

### Test
- Redis: Use separate test database
- Database: SQLite (`db/test.sqlite3`)
- Cache: Test adapter

### Production
- Redis: Use `REDIS_URL` environment variable
- Database: Configure via `DATABASE_URL`
- Cache: Redis with appropriate TTLs

## Getting Help

### Architecture Decisions
For architectural guidance, ask: "Can the architecture team review this approach?"
The team includes:
- Systems Architect
- Domain Expert
- Rails Specialist
- Security Specialist
- Redis Specialist
- Performance Specialist
- Testing Specialist

### Code Reviews
Request specific reviews:
- "Can the Rails Specialist review this controller?"
- "Can the Security Specialist review this authentication approach?"
- "Can the Testing Specialist suggest tests for this service?"

### Documentation
- Architecture: `.architecture/`
- ADRs: `.architecture/decisions/adrs/`
- Principles: `.architecture/principles.md`
- README: Project root `README.md`

## Important Reminders

1. **NEVER use puts** - Always use `debug_me`
2. **Design for testability** - Every method must be easily tested in isolation
3. **Follow Rails conventions** - Unless there's a compelling reason documented in an ADR
4. **Cache aggressively** - Weather data is perfect for caching
5. **Document decisions** - Create ADRs for significant architectural choices
6. **Security first** - Consider security implications of every endpoint
7. **Performance matters** - API latency directly impacts user experience

---

*Last Updated*: 2025-10-10
