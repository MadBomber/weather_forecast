# WeatherForecast API - Project Context

## Project Overview

**WeatherForecast** is a Ruby on Rails 8.0.3 API-only application designed to integrate with third-party weather data providers and expose weather conditions and forecast data through a unified RESTful API.

## Core Purpose

This application serves as an **aggregation and normalization layer** for multiple weather data sources, providing:

1. **Unified Interface**: Single API for consuming weather data from multiple providers
2. **Data Normalization**: Consistent data format regardless of source provider
3. **Performance Optimization**: Intelligent caching to reduce external API calls and improve response times
4. **Reliability**: Fallback capabilities across multiple weather providers
5. **Abstraction**: Shield consumers from provider-specific implementations

## Integration Focus

### Third-Party Weather Data Providers

The application integrates with external weather API services:

1. **National Weather Service (NWS)** - via `nws_openapi_sdk` gem
   - US government weather data
   - No API key required
   - US-focused coverage
   - Free service

2. **OpenWeatherMap** - via `openweathermap` gem
   - Global weather coverage
   - Requires API key
   - Rich feature set
   - Free tier available

### Integration Architecture

- **Adapter Pattern**: Each weather provider has its own adapter implementing a common interface
- **Service Layer**: Business logic isolated from external API specifics
- **Data Transformation**: Provider data transformed into normalized domain objects
- **Error Handling**: Graceful degradation when providers are unavailable

## Technical Architecture

### Technology Stack

- **Framework**: Rails 8.0.3 (API-only mode)
- **Language**: Ruby 3.4.6
- **Web Server**: Falcon (HTTP/2 via falcon-rails)
- **Cache Layer**: Redis 5.4+
- **Database**: SQLite (development), configurable for production
- **Testing**: RSpec
- **Background Jobs**: Solid Queue

### Key Architectural Decisions

See `.architecture/decisions/adrs/` for detailed ADRs:

- **ADR-0001**: Use Redis for caching and Action Cable
- Weather API integration approach (to be documented)

## Use Cases

### Primary Use Cases

1. **Current Weather Retrieval**: Get current weather conditions for a location
2. **Forecast Retrieval**: Get multi-day weather forecasts
3. **Multiple Provider Support**: Switch between or aggregate data from multiple sources
4. **Cached Responses**: Minimize external API calls through intelligent caching
5. **Real-time Updates**: Potential WebSocket support for weather alerts

### API Consumers

Expected consumers of this API:
- Web applications displaying weather information
- Mobile applications requiring weather data
- IoT devices needing weather conditions
- Other backend services requiring weather context
- Dashboard and visualization tools

## Data Flow

```
Client Request
    ↓
Rails API Controller
    ↓
Service Layer (checks cache)
    ↓
Cache Hit? → Return cached data
    ↓
Cache Miss
    ↓
Weather Provider Adapter (NWS or OpenWeatherMap)
    ↓
External Weather API
    ↓
Transform Response to Domain Objects
    ↓
Cache Response (Redis)
    ↓
Return to Client
```

## Design Principles

### Integration-Specific Principles

1. **Provider Agnostic**: Application logic should not depend on specific provider
2. **Graceful Degradation**: Handle provider outages without total failure
3. **Efficient Caching**: Weather data changes slowly; cache aggressively
4. **Rate Limit Awareness**: Respect provider rate limits
5. **Data Normalization**: Expose consistent schema regardless of source
6. **Configuration Over Code**: Provider selection via configuration
7. **Observable Integration**: Log and monitor external API interactions

### Standard Principles

All standard architectural principles from `.architecture/principles.md` apply:
- API-First Design
- Performance Through Caching
- Testable by Design (use debug_me, not puts)
- Domain-Driven Design
- Rails Conventions
- Security by Default
- Scalability Through Statelessness

## Domain Model

### Core Entities

- **Location**: Geographic location for weather queries
- **Forecast**: Weather forecast data (temperature, conditions, etc.)
- **Temperature**: Value object with unit conversions
- **Conditions**: Weather condition descriptions
- **Provider**: Weather data source abstraction

### Weather Data Attributes

Expected data points from providers:
- Temperature (with unit conversion)
- Weather conditions (sunny, cloudy, rainy, etc.)
- Humidity
- Wind speed and direction
- Precipitation probability
- Atmospheric pressure
- UV index
- Forecast period (current, hourly, daily)

## Configuration

### Environment Variables

Required configuration:
- `REDIS_URL`: Redis connection string
- `OPENWEATHERMAP_API_KEY`: OpenWeatherMap API key (if using)
- `DEFAULT_WEATHER_PROVIDER`: Default provider (nws, openweathermap)
- `WEATHER_CACHE_TTL`: Cache time-to-live override

### Provider Configuration

Provider selection and fallback strategy configurable via:
- Environment variables
- Rails credentials
- Configuration files

## Development Workflow

### Adding New Weather Providers

To integrate a new weather provider:
1. Create adapter class inheriting from `Weather::BaseAdapter`
2. Implement required methods (current_weather, forecast)
3. Transform provider data to domain objects
4. Add provider-specific configuration
5. Write RSpec tests for adapter
6. Document in ADR
7. Update provider selection logic

### Testing Strategy

- **Unit Tests**: Test adapters in isolation with mocked external calls
- **Integration Tests**: Test with real API calls (use VCR for recording)
- **Controller Tests**: Test API endpoints with mocked services
- **Contract Tests**: Ensure adapters honor the interface

## Future Enhancements

Potential features:
- Historical weather data
- Weather alerts and notifications
- Location search and geocoding
- Multi-provider aggregation (average, consensus)
- Weather data persistence for analytics
- GraphQL API in addition to REST
- WebSocket updates for real-time weather changes

## Key Constraints

1. **External Dependencies**: Reliant on third-party API availability
2. **Rate Limits**: Subject to provider rate limits
3. **Coverage**: Geographic coverage varies by provider
4. **Data Freshness**: Dependent on provider update frequency
5. **API Keys**: Some providers require registration and keys

## Success Metrics

- API response time (target: <200ms for cached, <2s for uncached)
- Cache hit rate (target: >80%)
- External API error rate (target: <1%)
- Uptime (target: 99.9%)
- Provider failover success rate

---

*Last Updated*: 2025-10-10
*Status*: Active Development
*Focus*: Third-Party Weather Data Integration
