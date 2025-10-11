# ADR-0005: No Database Management System for Initial Implementation

## Status

Accepted

## Context

The WeatherForecast API is a Rails 8 application that integrates with third-party weather data providers. As a Rails application, the framework includes database support by default (currently configured with SQLite in development).

We need to decide whether to actively use a database management system (DBMS) for storing application data, or whether the application can function effectively without persistent database storage.

### Potential Use Cases for Database

**Considered Database Uses**:
1. **Geocoding Cache**: Store zipcode → lat/lon conversions to avoid repeated geocoding API calls
2. **User Management**: Store user accounts and API keys
3. **Usage Analytics**: Track API usage by user/location
4. **Historical Weather Data**: Archive weather data for trends
5. **Favorites/Preferences**: Store user location preferences
6. **Rate Limiting**: Track API usage per user
7. **Audit Logs**: Record all weather data requests

### Application Focus

The **primary focus** of this application is:
- Third-party weather data API integration
- Providing a clean, unified API for weather data
- Efficient caching of weather information
- Transformation and normalization of provider data

The application is **not** focused on:
- User management
- Historical data analytics
- Complex business logic requiring persistence
- Multi-tenant data isolation

### Current Architecture

**What We Have**:
- Redis for caching (30-minute TTL for weather data)
- Stateless API design
- External API integration (OpenWeatherMap, NWS)
- No user authentication/authorization currently

**What Would Need Database**:
The most compelling use case identified was **geocoding cache** (zipcode → lat/lon conversion):
- Both weather providers recommend lat/lon for accuracy
- Zipcodes are static (rarely change)
- Geocoding APIs have rate limits and costs
- Could cache geocoding results permanently

### Analysis of Geocoding Cache

**Benefits of Database for Geocoding**:
- Permanent cache of zipcode → lat/lon mappings
- Avoid repeated geocoding API calls
- No expiration needed (zipcodes stable)
- Reduce dependency on geocoding service

**Alternatives to Database**:
- **In-Memory Cache** (Redis): Store geocoding results with long TTL (90 days)
- **Static Data File**: Load common zipcodes from CSV/JSON
- **Defer Decision**: Add geocoding later when needed
- **Accept API Calls**: Use provider's zipcode support (less accurate)

**Current Recommendation**:
OpenWeatherMap accepts zipcode directly. While lat/lon is recommended for accuracy, zipcode support is adequate for initial implementation. Geocoding optimization can be added later if accuracy becomes an issue.

## Decision

We will **NOT use a database management system** in the initial implementation of the WeatherForecast API.

### Rationale

**1. Application Focus**:
- Core mission is weather API integration, not data management
- Adding database is scope creep for initial MVP
- Can deliver value without persistence layer
- Focus on doing one thing well: API aggregation

**2. Simplicity**:
- Fewer moving parts to deploy and maintain
- No database migrations to manage
- No schema design complexity
- Faster development velocity
- Simpler deployment architecture

**3. Stateless API Design**:
- Application is designed to be stateless
- Redis provides necessary caching
- No session data to persist
- Aligns with API-only, frontend/backend separation (ADR-0002)

**4. Redis Sufficient for Needs**:
- Weather data caching: Redis with TTL ✓
- Geocoding cache: Redis with long TTL (if needed) ✓
- Session management: Not needed currently ✓
- Rate limiting: Can use Redis counters ✓

**5. Geocoding Not Immediately Needed**:
- OpenWeatherMap supports zipcode input
- Can use zipcode directly in phase 1
- Add geocoding optimization later if accuracy issues arise
- Defer complexity until proven necessary

**6. YAGNI Principle**:
- "You Aren't Gonna Need It"
- Don't build infrastructure for hypothetical future needs
- Add database when concrete requirement emerges
- Avoid premature optimization

### Implementation Approach

**Phase 1** (Current - No Database):
- Use OpenWeatherMap zipcode support directly
- Redis for weather data caching
- Stateless API endpoints
- No persistent storage

**Phase 2** (If Geocoding Needed):
- Add geocoding service (Google, Mapbox, etc.)
- Cache results in Redis with long TTL (90 days)
- Monitor accuracy and performance
- Evaluate if permanent storage needed

**Phase 3** (If Database Required):
- Add PostgreSQL 18+ (see below)
- Migrate geocoding cache from Redis to PostgreSQL
- Add database-appropriate features (analytics, user management, etc.)
- Run migrations and update deployment

### Future Database Preference: PostgreSQL 18+

**If a database becomes necessary**, the preference is **PostgreSQL version 18 or later**.

**Rationale for PostgreSQL**:
- Industry-standard for production Rails applications
- Excellent Rails integration and tooling
- Advanced features (JSON/JSONB, full-text search, spatial data)
- Strong data integrity and ACID compliance
- Open source with commercial support available
- Large ecosystem and community
- PostGIS extension for geospatial queries (useful for lat/lon)
- Superior performance for complex queries
- Better scalability than SQLite for production

**Why Version 18+**:
- Latest features and performance improvements
- Modern SQL capabilities
- Improved query planner
- Better JSON support
- Enhanced performance monitoring
- Security updates

## Consequences

### Positive Consequences

1. **Simplicity**:
   - Fewer infrastructure components
   - Simpler deployment (no database setup)
   - No database migrations to manage
   - Faster development iteration

2. **Focus**:
   - Team focuses on weather API integration
   - Core competency: API aggregation and caching
   - Avoid database design distractions
   - Cleaner separation of concerns

3. **Cost**:
   - No database hosting costs
   - Reduced infrastructure complexity
   - Lower operational overhead
   - Redis already required, no additional services

4. **Performance**:
   - Redis-only caching is extremely fast
   - No database query latency
   - Simpler monitoring
   - Fewer failure points

5. **Deployment**:
   - Easier to containerize
   - Faster startup time
   - Simpler scaling (stateless)
   - No database backups needed

6. **Flexibility**:
   - Can add database later without regret
   - Not locked into database decisions prematurely
   - Can choose database based on actual needs

### Negative Consequences

1. **Geocoding Limitation**:
   - Cannot permanently cache zipcode → lat/lon mappings
   - Redis cache can be lost on restart (though unlikely with persistence)
   - May need to re-geocode after cache expiration
   - Geocoding API dependency

2. **No Historical Data**:
   - Cannot store historical weather data
   - No trending or analytics on past data
   - Cannot serve historical queries
   - Dependent on providers for historical data

3. **No User Management**:
   - Cannot implement user accounts without database
   - No API key management per user
   - No usage tracking per user
   - Limited to public API or shared authentication

4. **No Audit Trail**:
   - Cannot log requests permanently
   - No historical usage analytics
   - Harder to debug past issues
   - Compliance/audit limitations

5. **Redis Dependency**:
   - All caching dependent on Redis
   - Redis restart loses cache (performance impact)
   - Need Redis persistence enabled
   - Single point of failure for caching

6. **Future Migration**:
   - Adding database later requires code changes
   - May need to migrate cached data
   - Architectural changes if needs evolve
   - Potential downtime during migration

### Neutral Consequences

1. **SQLite Remains Available**:
   - Rails still includes SQLite for Solid Queue/Cache
   - Could use SQLite for simple local storage if needed
   - Not a production database choice

2. **Redis as Persistent Store**:
   - Can enable Redis persistence (RDB/AOF)
   - Makes Redis more database-like
   - Increases Redis importance in architecture

## Alternatives Considered

### 1. Use PostgreSQL from Day One

**Description**: Add PostgreSQL immediately for geocoding cache and future features

**Why Not Chosen**:
- **Premature**: No proven need for persistence yet
- **Complexity**: Adds infrastructure and operational burden
- **Scope Creep**: Not aligned with core API integration focus
- **YAGNI**: Building for hypothetical future needs
- **Cost**: Additional infrastructure to deploy and maintain

**When It Would Be Better**:
- Application requires user management from start
- Historical data storage is core requirement
- Complex relational data models needed
- Compliance/audit logging required
- Multi-tenancy with data isolation

### 2. Use SQLite for Geocoding Cache

**Description**: Use existing SQLite setup for caching geocoding results

**Why Not Chosen**:
- **Not Production Ready**: SQLite not suitable for production at scale
- **Limited Concurrency**: Struggles with concurrent writes
- **Deployment Issues**: File-based database complicates containerization
- **Not Worth It**: If we need persistence, use proper database (PostgreSQL)
- **Half Measure**: Either go database-free or use production-grade database

**When It Would Be Better**:
- Local development tool
- Single-user application
- Embedded applications
- Prototyping

### 3. Use Redis for Long-Term Geocoding Cache

**Description**: Store zipcode → lat/lon in Redis with very long TTL (90+ days)

**Why Not Chosen for "Not Chosen"**:
- Actually, this IS the recommended approach if geocoding is needed
- Redis with long TTL provides 90% of database benefits
- Simpler than adding PostgreSQL
- Aligns with stateless architecture

**Implementation** (if geocoding added):
```ruby
# Cache zipcode → lat/lon for 90 days
Rails.cache.write("geocode:#{zipcode}", {lat: lat, lon: lon}, expires_in: 90.days)
```

### 4. Use Managed Database Service (e.g., Supabase)

**Description**: Use managed PostgreSQL service for zero-ops database

**Why Not Chosen**:
- Still adds database even if managed
- Doesn't solve "do we need database?" question
- Additional cost
- Vendor lock-in

**When It Would Be Better**:
- When database is needed but team lacks PostgreSQL expertise
- Rapid prototyping with database features
- Need PostgreSQL features with minimal ops

## Implementation Guidelines

### Current Implementation (No Database)

1. **Weather Data Caching**:
   ```ruby
   # Cache in Redis with 30-minute TTL
   Rails.cache.write(
     "weather:#{provider}:#{zipcode}:#{hour}",
     weather_data,
     expires_in: 30.minutes
   )
   ```

2. **Geocoding** (if needed later):
   ```ruby
   # Cache in Redis with long TTL
   Rails.cache.fetch("geocode:#{zipcode}", expires_in: 90.days) do
     geocoding_service.convert(zipcode)
   end
   ```

3. **Rate Limiting** (if needed):
   ```ruby
   # Use Redis counters
   key = "rate_limit:#{api_key}:#{Time.current.to_i / 60}"
   Rails.cache.increment(key, 1, expires_in: 1.minute)
   ```

### When to Add Database

**Triggers for Adding PostgreSQL**:

1. **User Management Required**:
   - Need to store user accounts
   - API key management per user
   - Role-based access control

2. **Historical Data Storage**:
   - Store weather data long-term
   - Analytics on historical trends
   - Archival requirements

3. **Geocoding Cache Volume**:
   - Caching thousands of zipcodes
   - Redis memory constraints
   - Need permanent storage

4. **Complex Queries**:
   - Relational data models emerge
   - Need JOIN queries
   - Full-text search requirements

5. **Compliance/Audit**:
   - Regulatory requirements for data retention
   - Audit logging needed
   - Data integrity critical

### Migration Path to PostgreSQL

**When database becomes necessary**:

1. **Add PostgreSQL**:
   ```ruby
   # Gemfile
   gem 'pg', '~> 1.5'

   # database.yml
   production:
     adapter: postgresql
     url: <%= ENV['DATABASE_URL'] %>
   ```

2. **Create Migrations**:
   ```bash
   rails generate model Geocode zipcode:string latitude:decimal longitude:decimal
   rails db:migrate
   ```

3. **Migrate Redis Cache** (if needed):
   ```ruby
   # Background job to migrate cached data to database
   Redis.scan_each(match: "geocode:*") do |key|
     zipcode = key.split(":").last
     data = Rails.cache.read(key)
     Geocode.create!(zipcode: zipcode, **data)
   end
   ```

4. **Update Application Code**:
   - Switch from Redis to database for persistent data
   - Keep Redis for temporary caching
   - Update service objects

5. **Deploy and Monitor**:
   - Test migration thoroughly
   - Monitor database performance
   - Tune PostgreSQL configuration

## Related Decisions

- **ADR-0001**: Redis caching - Primary data storage mechanism
- **ADR-0002**: API-only architecture - Stateless design supports database-free approach
- **ADR-0003**: Falcon web server - Async I/O works well without database
- **ADR-0004**: OpenWeatherMap - Supports zipcode directly, reduces geocoding need

## References

- [YAGNI Principle](https://martinfowler.com/bliki/Yagni.html)
- [Redis Persistence](https://redis.io/docs/management/persistence/)
- [PostgreSQL 18 Release Notes](https://www.postgresql.org/docs/18/release-18.html)
- [Rails Database Configuration](https://guides.rubyonrails.org/configuring.html#configuring-a-database)
- [PostGIS for Geospatial Data](https://postgis.net/)

## Review Notes

This decision reflects:
- **Minimalism**: Build only what's needed now
- **Focus**: Core competency is API integration, not data management
- **Pragmatism**: Redis sufficient for current requirements
- **Flexibility**: Clear path to add PostgreSQL when needed
- **YAGNI**: Avoid premature infrastructure

The decision acknowledges that databases are powerful tools, but adds them when concrete requirements emerge rather than hypothetical future needs.

**Key Insight**: The most compelling database use case (geocoding cache) can be adequately handled by Redis with long TTL, and OpenWeatherMap's zipcode support reduces the immediate need for geocoding accuracy optimization.

---

*Date*: 2025-10-10
*Author*: Architecture Team
*Reviewers*: Systems Architect, Rails Specialist, Performance Specialist
*Related ADRs*: ADR-0001 (Redis), ADR-0002 (API-Only), ADR-0004 (OpenWeatherMap)
*Future Preference*: PostgreSQL 18+ if database becomes necessary
*Review Trigger*: Revisit if user management, historical data, or compliance requirements emerge
