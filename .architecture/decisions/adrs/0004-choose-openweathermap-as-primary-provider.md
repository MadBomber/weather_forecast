# ADR-0004: Choose OpenWeatherMap as Primary Weather Data Provider

## Status

Accepted

## Context

The WeatherForecast API needs to integrate with at least one third-party weather data provider to retrieve current conditions and forecast data. The application has already included integration gems for two major providers:

1. **National Weather Service (NWS)** - via `nws_openapi_sdk` gem
2. **OpenWeatherMap (OWM)** - via `openweathermap` gem

We need to decide which provider to use as the primary/default weather data source.

### Provider Comparison

#### National Weather Service (NWS)

**Pros**:
- **Free**: No cost, no usage limits
- **No API Key Required**: No registration or authentication needed
- **Government Data**: Authoritative US weather data source
- **Reliability**: Government-backed infrastructure
- **No Rate Limits**: Generous usage terms
- **Public Service**: Designed for public access

**Cons**:
- **US-Only Coverage**: Only provides data for locations within the United States
- **Geographic Limitation**: Cannot serve international users
- **Location Format**: Requires latitude/longitude coordinates (not zipcode)
- **Limited Scalability**: If application expands internationally, requires second provider

**API Characteristics**:
- Input: Latitude/Longitude coordinates
- Coverage: United States only
- Authentication: None required
- Rate Limits: None specified (reasonable use expected)
- Data Quality: High (authoritative source)

#### OpenWeatherMap (OWM)

**Pros**:
- **Global Coverage**: Weather data for any location worldwide
- **Scalability**: Can support international expansion
- **Free Tier**: Sufficient for development and early production
- **Flexible Input**: Supports zipcode, city name, and lat/lon coordinates
- **Rich Features**: Current weather, forecasts, historical data, alerts
- **Well Documented**: Extensive API documentation and examples
- **Established Service**: Long-standing provider with track record

**Cons**:
- **Requires API Key**: Must register and manage API credentials
- **Free Tier Limitations**:
  - 1,000 calls/day on free tier
  - 60 calls/minute rate limit
  - May require paid tier for production scale
- **Cost at Scale**: Paid plans required for higher volume
- **Accuracy Concerns**: While supports zipcode, recommends lat/lon for accuracy
- **Rate Limit Management**: Need to handle rate limiting gracefully

**API Characteristics**:
- Input: Zipcode, city name, or lat/lon (lat/lon recommended for accuracy)
- Coverage: Global
- Authentication: API key required
- Rate Limits:
  - Free: 1,000 calls/day, 60 calls/min
  - Paid tiers available for scale
- Data Quality: Good (commercial provider)

### Application Requirements

**Current Requirements**:
- Support zipcode-based queries (30-minute cache per zipcode)
- Fast response times (<200ms cached, <2s uncached)
- Development and testing support
- Production deployment capability

**Future Considerations**:
- Potential international expansion
- Mobile app deployment
- Third-party integrations
- Commercial use

### Location Input Analysis

Both providers ultimately recommend **latitude/longitude coordinates** for most accurate data:

- **NWS**: Requires lat/lon, no zipcode support
- **OWM**: Supports zipcode but recommends lat/lon for accuracy

**Implication**: Application may need geocoding service to convert zipcodes to lat/lon coordinates for best accuracy, regardless of provider choice.

## Decision

We will use **OpenWeatherMap (OWM) as the primary weather data provider**.

### Rationale

**1. Global Coverage**
- Supports international locations from day one
- No geographic limitations
- Future-proof for expansion

**2. Development Feasibility**
- Free tier (1,000 calls/day) is sufficient for:
  - Development and testing
  - Early production with caching
  - Proof of concept

**3. Caching Mitigates Rate Limits**
- 30-minute cache per zipcode drastically reduces API calls
- Example: 100 unique locations × 48 calls/day (30-min intervals) = 4,800 calls/day
- With typical usage patterns and caching, free tier may suffice for initial production

**4. Scalability Path**
- Clear upgrade path to paid tiers ($40-$180/month for higher limits)
- Can scale gradually as user base grows
- No hard geographic walls

**5. Flexibility**
- Multiple input formats (zipcode, city, lat/lon)
- Can start with zipcode, migrate to lat/lon later
- Rich feature set for future enhancements

**6. NWS as Potential Fallback**
- Can add NWS as fallback for US locations
- Provider abstraction (adapter pattern) supports multiple sources
- Best of both: OWM primary, NWS fallback/cost savings for US

### Implementation Strategy

**Phase 1: OpenWeatherMap Only**
- Implement OWM adapter
- Support zipcode and lat/lon inputs
- Implement 30-minute caching
- Monitor API usage against free tier limits

**Phase 2: Optimization** (if needed)
- Add geocoding for zipcode → lat/lon conversion
- Implement smarter caching strategies
- Analyze usage patterns

**Phase 3: Multi-Provider** (future)
- Add NWS adapter for US locations (free, reduce OWM usage)
- Implement provider selection logic (US = NWS, international = OWM)
- Fallback between providers

### Configuration

```ruby
# Environment variables
OPENWEATHERMAP_API_KEY=<api_key>
DEFAULT_WEATHER_PROVIDER=openweathermap

# Future multi-provider support
WEATHER_PROVIDER_SELECTION=smart  # auto-select based on location
```

## Consequences

### Positive Consequences

1. **No Geographic Limitations**:
   - Application works globally from day one
   - Can serve international users
   - No feature limitations by region

2. **Development Friendly**:
   - Free tier sufficient for development
   - Easy to get started (just register for API key)
   - Good documentation and examples

3. **Scalable**:
   - Clear growth path via paid tiers
   - Caching significantly reduces API call volume
   - Can optimize costs with multi-provider strategy later

4. **Flexible Input**:
   - Supports zipcode (user-friendly)
   - Supports lat/lon (accurate)
   - Can evolve input strategy without provider change

5. **Future-Proof**:
   - Global coverage supports expansion
   - Rich feature set (alerts, historical data)
   - Can add NWS as cost optimization later

6. **Commercial Viability**:
   - Legitimate paid tiers for commercial use
   - Clear pricing structure
   - Established business model

### Negative Consequences

1. **API Key Management**:
   - Must securely store and rotate API keys
   - Keys must be configured in all environments
   - Risk of key exposure or theft

2. **Cost Considerations**:
   - Free tier may not support production scale
   - Need to monitor usage and budget for paid tier
   - Costs increase with user growth
   - Estimated costs:
     - Startup (1M calls/month): ~$40/month
     - Professional (10M calls/month): ~$180/month

3. **Rate Limit Risk**:
   - Free tier: 1,000 calls/day limit
   - Could hit limits without proper caching
   - Need monitoring and alerting for rate limits
   - Must implement graceful degradation

4. **Vendor Lock-in** (mild):
   - Initial implementation tied to OWM
   - Switching providers requires code changes
   - Mitigated by adapter pattern

5. **Dependency**:
   - Reliant on OWM service availability
   - Subject to OWM API changes
   - Subject to pricing changes

6. **Data Accuracy**:
   - While good, may not match NWS accuracy for US locations
   - Zipcode-based queries less accurate than lat/lon

### Neutral Consequences

1. **Geocoding May Be Needed**:
   - For best accuracy, convert zipcode → lat/lon
   - Adds another service dependency
   - Could use Google Geocoding API or similar

2. **Multi-Provider in Future**:
   - Adapter pattern supports adding NWS later
   - Can optimize costs by routing US traffic to NWS

## Alternatives Considered

### 1. National Weather Service (NWS) as Primary

**Why Not Chosen**:
- **Geographic Limitation**: US-only coverage is a hard constraint
- **No International Support**: Cannot serve non-US users
- **Future Limitations**: Requires second provider for global expansion
- **Not Future-Proof**: Known limitation from day one

**When It Would Be Better**:
- Application explicitly only serves US users
- Cost optimization is critical (free is best)
- Government data source required (e.g., grant-funded project)
- No international expansion plans

**Still Valuable**:
- Can add NWS as fallback/optimization later
- Reduce OWM costs for US locations
- Improve redundancy

### 2. Weather.com / The Weather Channel API

**Description**: Enterprise weather API from The Weather Channel

**Why Not Chosen**:
- No free tier
- More expensive than OWM
- Overkill for initial needs
- Commercial focus

**When It Would Be Better**:
- Enterprise deployment
- Need premium support
- Brand recognition important

### 3. AccuWeather API

**Description**: Commercial weather API provider

**Why Not Chosen**:
- Limited free tier (50 calls/day - too restrictive)
- More expensive than OWM
- Stricter API terms
- Less developer-friendly

**When It Would Be Better**:
- Need AccuWeather branding
- Enterprise requirements
- Specific AccuWeather features needed

### 4. Multi-Provider from Day One

**Description**: Implement both NWS and OWM with routing logic

**Why Not Chosen**:
- Premature optimization
- Doubles implementation complexity
- Not needed until scaling issues arise
- Can add later when needed

**When It Would Be Better**:
- High-volume application from launch
- Cost optimization critical
- Redundancy required from start

## Implementation Guidelines

### Phase 1: Initial Implementation

1. **Setup**:
   - Register for OpenWeatherMap API key
   - Store key in Rails credentials: `rails credentials:edit`
   - Configure in environment variables for deployment

2. **Adapter Implementation**:
   - Create `Weather::OpenweathermapAdapter`
   - Support both zipcode and lat/lon inputs
   - Implement 30-minute caching
   - Handle rate limit errors gracefully

3. **Monitoring**:
   - Track API call volume
   - Monitor rate limit headers
   - Alert when approaching limits
   - Log cache hit rates

### Usage Estimation with Caching

**Assumptions**:
- 30-minute cache per zipcode
- 100 unique locations/day
- Even distribution

**Calculation**:
- Calls per location per day: 24 hours / 0.5 hours = 48
- Total calls: 100 locations × 48 = 4,800 calls/day
- Free tier: 1,000 calls/day

**Conclusion**: Need paid tier or reduce unique locations

**With Effective Caching** (80% hit rate):
- Actual API calls: 4,800 × 20% = 960 calls/day
- Within free tier limits ✓

### Rate Limit Handling

```ruby
rescue OpenWeatherMap::RateLimitError => e
  # Log error
  # Return cached data if available (even if stale)
  # Alert operations team
  # Consider fallback to NWS for US locations
end
```

### Cost Planning

- **Free Tier**: Development, testing, proof of concept
- **Startup Tier** (~$40/month): 1M calls/month = ~33,000 calls/day
- **Professional Tier** (~$180/month): 10M calls/month = ~333,000 calls/day

## Success Metrics

1. **API Usage**: Stay within budget tier (monitor daily)
2. **Cache Hit Rate**: Target >80% to minimize API calls
3. **Response Time**: <200ms cached, <2s uncached
4. **Reliability**: <0.1% API error rate
5. **Cost**: Optimize for lowest tier that meets demand

## Future Enhancements

1. **Add NWS as Fallback** (US locations):
   - Route US requests to NWS (free)
   - Fall back to OWM if NWS fails
   - Reduce OWM costs by ~60% (assuming US-heavy traffic)

2. **Geocoding Service**:
   - Convert zipcode → lat/lon for accuracy
   - Cache geocoding results
   - Improve data quality

3. **Provider Abstraction**:
   - Support multiple providers
   - Smart routing based on location
   - Load balancing across providers

## Related Decisions

- **ADR-0001**: Redis caching critical for staying within rate limits
- **ADR-0002**: API-only architecture simplifies provider integration
- **ADR-0003**: Falcon async I/O good for external API calls

## References

- [OpenWeatherMap API Pricing](https://openweathermap.org/price)
- [OpenWeatherMap API Documentation](https://openweathermap.org/api)
- [National Weather Service API](https://www.weather.gov/documentation/services-web-api)
- [NWS API Specification](https://www.weather.gov/documentation/services-web-api)
- [Geocoding Best Practices](https://developers.google.com/maps/documentation/geocoding/overview)

## Review Notes

This decision reflects:
- **Global mindset**: Planning for international use from start
- **Pragmatic scaling**: Start with free tier, upgrade as needed
- **Cost awareness**: Caching strategy designed to minimize API calls
- **Flexibility**: Adapter pattern allows adding NWS later for optimization
- **Development velocity**: Get started quickly with good free tier

The decision acknowledges free tier limitations while demonstrating a path to scale through caching optimization and potential multi-provider strategy.

---

*Date*: 2025-10-10
*Author*: Architecture Team
*Reviewers*: Systems Architect, Domain Expert, Performance Specialist
*Related ADRs*: ADR-0001 (Redis Caching), ADR-0002 (API-Only), ADR-0003 (Falcon)
*Implementation Priority*: High - Required for core functionality
