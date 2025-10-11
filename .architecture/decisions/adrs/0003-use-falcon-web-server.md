# ADR-0003: Use Falcon as Application Web Server

## Status

Accepted

## Context

The WeatherForecast API needs a web server to handle HTTP requests. As a Rails 8 API-only application, the choice of web server impacts performance, concurrency handling, and development experience.

### Web Server Requirements

**Functional Requirements**:
- Handle concurrent HTTP requests efficiently
- Support HTTP/2 for improved performance
- Integrate seamlessly with Rails
- Provide good development experience
- Support WebSocket connections (Action Cable)

**Performance Requirements**:
- Low latency for API responses
- Efficient handling of multiple simultaneous requests
- Good memory utilization
- Support for asynchronous I/O operations

### Available Options

Rails applications typically use one of several web servers:
- **Puma**: Rails default, thread-based concurrency
- **Unicorn**: Process-based, traditional forking model
- **Passenger**: Enterprise-grade, process/thread hybrid
- **Falcon**: Modern, fiber-based with native HTTP/2 support

### Developer Motivation

**Learning Opportunity**: The lead engineer identified this project as an opportunity to gain hands-on experience with Falcon, having never used it in production before.

**Developer Credentials**: Falcon is developed by **Samuel Williams** (ioquatix), who is also the author of:
- **async**: Composable asynchronous I/O framework for Ruby
- **protocol-http**: HTTP protocol implementations
- **async-io**: Asynchronous I/O primitives
- **async-websocket**: Asynchronous WebSocket support
- Many other high-quality async Ruby libraries

Samuel Williams has established credibility in the Ruby async ecosystem, making Falcon a technically sound choice backed by solid engineering principles.

### Why Try Falcon?

1. **Technical Merit**: Fiber-based concurrency model aligns with modern Ruby async patterns
2. **HTTP/2 Native**: Built-in HTTP/2 support without additional configuration
3. **Learning Value**: Expand team's understanding of async Ruby and fiber-based concurrency
4. **Ecosystem**: Part of a well-maintained async Ruby ecosystem
5. **Community**: Growing adoption in the Ruby community
6. **Low Risk**: Can switch to Puma if Falcon doesn't meet expectations

## Decision

We will use **Falcon** as the web server for the WeatherForecast API via the `falcon-rails` gem.

### Implementation

**Gem**: `falcon-rails` (~> 0.2.4)
- Provides Rails integration for Falcon
- Simplifies configuration and deployment
- Handles development and production modes

**Configuration**:
- Use Falcon in development and production
- Leverage HTTP/2 capabilities for API clients that support it
- Configure appropriate concurrency settings
- Monitor performance and adjust as needed

**Fallback Plan**:
- Puma remains available as fallback if issues arise
- Can switch by changing Gemfile and configuration
- No fundamental architecture locked into Falcon-specific features

### Rationale

**Primary Motivation**: Learning and experimentation
- Project provides safe environment to evaluate Falcon
- Low-risk opportunity to gain production experience
- Weather API use case suits Falcon's async strengths

**Technical Benefits**:
- Fiber-based concurrency may handle concurrent API requests efficiently
- HTTP/2 support improves performance for modern clients
- Async I/O model potentially good fit for external API calls
- Part of cohesive async Ruby ecosystem

**Developer Expertise**: Falcon's author (Samuel Williams) has proven track record
- Maintains high-quality async Ruby libraries
- Active in Ruby community
- Solid understanding of async patterns and protocols

## Consequences

### Positive Consequences

1. **Learning Opportunity**:
   - Team gains experience with fiber-based Ruby web servers
   - Understanding of async Ruby ecosystem
   - Exposure to HTTP/2 in practice
   - Knowledge applicable to future projects

2. **HTTP/2 Support**:
   - Native HTTP/2 support without proxies
   - Multiplexing for efficient connections
   - Header compression
   - Server push capabilities (if needed)

3. **Modern Architecture**:
   - Fiber-based concurrency aligns with modern Ruby direction
   - Async I/O model for external API calls
   - Potentially better resource utilization

4. **Quality Codebase**:
   - Developed by respected Ruby async expert
   - Part of well-maintained ecosystem
   - Good documentation and community support

5. **Performance Potential**:
   - Efficient handling of I/O-bound operations (like API calls)
   - Low memory overhead compared to thread/process models
   - Good fit for API-heavy application

### Negative Consequences

1. **Less Proven**:
   - Smaller production deployment base than Puma
   - Fewer case studies and battle-tested scenarios
   - Less Stack Overflow/troubleshooting content

2. **Learning Curve**:
   - Team unfamiliar with Falcon configuration
   - Fiber-based concurrency has different characteristics than threads
   - May encounter unexpected issues
   - Debugging async issues can be complex

3. **Tooling and Ecosystem**:
   - Fewer third-party integrations
   - Some gems may not be fiber-safe
   - Performance monitoring tools may have limited Falcon support
   - APM tools may need special configuration

4. **Risk**:
   - Potential production issues unknown until deployed
   - May need to switch to Puma if problems arise
   - Time investment in learning may not pay off

5. **Deployment Complexity**:
   - Less common in hosting providers
   - Fewer deployment guides and examples
   - May require custom configuration

### Neutral Consequences

1. **Experimentation**: Project serves as learning platform
2. **Reversible Decision**: Can switch to Puma if needed
3. **Documentation**: Team will document learnings for future projects

## Alternatives Considered

### 1. Puma (Rails Default)

**Description**: Thread-based web server, Rails 8 default

**Why Not Chosen**:
- Team already familiar with Puma
- No learning opportunity
- Missed chance to explore modern alternatives
- Still a valid fallback option

**When It Would Be Better**:
- Production-critical application requiring proven technology
- Team needs familiar, well-documented server
- No time for experimentation
- Large existing Puma knowledge base in team

### 2. Unicorn

**Description**: Process-based forking web server

**Why Not Chosen**:
- Older architecture (pre-fork model)
- Higher memory usage
- No HTTP/2 support
- Not actively innovating
- No learning value (considered outdated)

**When It Would Be Better**:
- Legacy applications
- Simple deployment requirements
- No need for WebSockets or HTTP/2

### 3. Passenger

**Description**: Enterprise web server with commercial support

**Why Not Chosen**:
- Overkill for learning project
- Commercial licensing for advanced features
- More complex configuration
- No specific learning goals around Passenger

**When It Would Be Better**:
- Enterprise deployment with support requirements
- Complex routing and deployment needs
- Using Nginx/Apache integration features

## Implementation Guidelines

### Development

```bash
# Start with Falcon
bundle exec falcon serve

# Or use Rails default (uses Falcon via falcon-rails)
bundle exec rails server
```

### Production

```yaml
# Falcon configuration (config/falcon.rb or similar)
- Tune concurrency settings
- Configure workers based on server resources
- Set up monitoring and logging
- Document any Falcon-specific quirks
```

### Monitoring

- Track request latency
- Monitor fiber pool usage
- Watch for memory leaks
- Compare performance with Puma baseline

### Switching to Puma (If Needed)

1. Update Gemfile: Replace `falcon-rails` with `puma`
2. Update configuration files
3. Test thoroughly
4. Document reasons for switch

## Success Criteria

**Learning Goals**:
- Team understands fiber-based concurrency
- Documented experience with Falcon (pros/cons)
- Knowledge of when Falcon is appropriate

**Technical Goals**:
- API response times meet SLA (<200ms cached, <2s uncached)
- Stable under load
- No fiber-related bugs in production
- Successful HTTP/2 utilization

**Decision Point**:
- After 2-3 months, evaluate if Falcon meets needs
- Document findings in follow-up ADR
- Decide: continue with Falcon or switch to Puma

## Related Decisions

- **ADR-0001**: Redis caching reduces pressure on web server
- **ADR-0002**: API-only architecture simplifies web server requirements

## References

- [Falcon GitHub](https://github.com/socketry/falcon)
- [Falcon Rails Integration](https://github.com/socketry/falcon-rails)
- [Samuel Williams (async ecosystem)](https://github.com/socketry)
- [HTTP/2 Benefits](https://developers.google.com/web/fundamentals/performance/http2)
- [Ruby Fibers Guide](https://ruby-doc.org/core-3.4.0/Fiber.html)

## Review Notes

This decision reflects:
- **Pragmatic experimentation**: Using low-risk project to evaluate new technology
- **Developer growth**: Investing in team learning and skill development
- **Reversibility**: Clear fallback plan if Falcon doesn't work out
- **Trust in expertise**: Confidence in Samuel Williams' technical capabilities
- **Modern Ruby**: Alignment with Ruby's async/fiber direction

The decision acknowledges this is partially experimental while maintaining professional standards and fallback options.

---

*Date*: 2025-10-10
*Author*: Lead Engineer, Architecture Team
*Reviewers*: Systems Architect, Performance Specialist
*Related ADRs*: ADR-0001 (Redis), ADR-0002 (API-Only)
*Follow-up*: Plan to review after 2-3 months of production use
