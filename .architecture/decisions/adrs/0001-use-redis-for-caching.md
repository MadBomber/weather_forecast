# ADR-0001: Use Redis for Caching and Action Cable

## Status

Accepted

## Context

The WeatherForecast API needs a caching layer to:
- Reduce latency for repeated weather forecast requests
- Minimize calls to external weather APIs (which may have rate limits or costs)
- Provide fast response times for API consumers
- Support real-time weather updates via WebSockets (Action Cable)

### Specific Caching Requirements

**Time-To-Live (TTL) Management**:
- Weather data for specific locations (zipcodes) must be cached with automatic expiration
- **Requirement**: Cache weather data by zipcode for **30 minutes**
- After 30 minutes, cached data expires and fresh data is fetched
- TTL must be automatic (no manual cleanup needed)
- Different cache keys may need different TTLs

**Data Access Patterns**:
- Forecasts are typically updated every 15-60 minutes by providers
- Multiple clients may request the same zipcode data
- Data is time-sensitive but can be stale for short periods
- Popular locations (zipcodes) will be requested frequently
- Need to support location-based cache keys

Rails 8 defaults to database-backed caching solutions (Solid Cache), but our use case involves:
- High read/write frequency for cache operations
- Need for sub-millisecond cache access times
- **Critical requirement**: Built-in TTL support for automatic expiration
- Real-time WebSocket support requiring a shared pub/sub system
- Simple key-value data structures
- Location-based (zipcode) cache keys

## Decision

We will use Redis as the primary caching layer for:
1. **HTTP Cache Store**: Caching weather forecast API responses
2. **Action Cable Backend**: Managing WebSocket connections and pub/sub
3. **Session Store**: Storing API session data if needed

Configuration:
- Development: `redis://localhost:6379/0` (cache), `redis://localhost:6379/1` (cable)
- Production: Uses `REDIS_URL` environment variable
- Database 0: Cache store
- Database 1: Action Cable
- Rails cache store configured as `:redis_cache_store`
- **Default TTL**: 30 minutes for zipcode-based weather data
- Cache key format: `weather:{provider}:{zipcode}:{hour_bucket}`

We will NOT use Redis for:
- Primary data persistence (use PostgreSQL/SQLite)
- Background job queue (use Solid Queue with database)
- Full-text search (use database or dedicated search engine)

## Consequences

### Positive Consequences

- **Fast Cache Access**: Sub-millisecond read/write operations for cached weather data
- **Built-in TTL**: Native support for automatic expiration - perfect for 30-minute zipcode cache requirement
- **Automatic Cleanup**: Expired keys are automatically removed - no manual cleanup needed
- **Flexible Expiration**: Can set different TTLs for different data types (current weather, forecasts, etc.)
- **Battle-Tested**: Redis is mature, stable, and well-documented
- **Rails Integration**: Excellent Rails support via `redis-rb` gem and Rails cache store
- **Action Cable Support**: Native pub/sub capabilities for real-time weather updates
- **Data Structures**: Support for various data types (strings, hashes, lists, sets)
- **Monitoring**: Robust tools for monitoring cache hit rates and performance
- **Scalability**: Can be scaled independently of application servers
- **Zipcode Keys**: Efficient key-based storage for location-specific data

### Negative Consequences

- **Additional Infrastructure**: Requires running and maintaining a Redis instance
- **Memory Requirements**: All cached data stored in RAM
- **Single Point of Failure**: Need Redis clustering or sentinel for high availability
- **Complexity**: Additional service to configure, monitor, and backup
- **Cost**: Cloud Redis hosting may add infrastructure costs
- **Data Loss Risk**: Redis data is volatile (though acceptable for cache)

### Neutral Consequences

- **Operational Knowledge**: Team needs to understand Redis operations and monitoring
- **Development Setup**: Developers need Redis running locally
- **Configuration Management**: Need to manage Redis connection strings across environments

## Alternatives Considered

### 1. Solid Cache (Database-Backed)
**Description**: Rails 8 default, stores cache in SQLite/PostgreSQL
**Why Not Chosen**:
- Slower than in-memory cache for high-frequency access
- Adds load to primary database
- **No built-in TTL support** - would need manual cleanup or scheduled jobs
- Managing expiration of zipcode caches would require custom implementation
- No native pub/sub for Action Cable
- Would need separate solution for real-time features

### 2. Memcached
**Description**: Pure in-memory caching system
**Why Not Chosen**:
- No pub/sub support (need separate solution for Action Cable)
- Less feature-rich data structures
- No persistence option
- Redis offers more functionality for similar operational overhead

### 3. In-Memory Cache (Memory Store)
**Description**: Rails built-in memory-based cache
**Why Not Chosen**:
- Not shared across application instances
- Lost on application restart
- Unsuitable for production with multiple servers
- No Action Cable support

### 4. CDN Caching (e.g., Cloudflare)
**Description**: Edge caching for API responses
**Why Not Chosen**:
- Doesn't solve Action Cable requirement
- Less control over cache invalidation
- Better suited for static content
- Could be added later as additional caching layer

## References

- [Redis Documentation](https://redis.io/docs/)
- [Rails Caching Guide](https://guides.rubyonrails.org/caching_with_rails.html)
- [Action Cable Redis Adapter](https://guides.rubyonrails.org/action_cable_overview.html#redis)
- [Redis Best Practices](https://redis.io/docs/management/optimization/)

---

*Date*: 2025-10-10
*Author*: Architecture Team
*Reviewers*: Systems Architect, Redis Specialist, Performance Specialist
