# ADR-0002: API-Only Rails Application with Frontend/Backend Separation

## Status

Accepted

## Context

When building a weather forecast application that integrates with third-party weather data providers, we must decide on the application architecture. The fundamental choice is between:

1. **Monolithic Rails Application**: Traditional Rails app with server-side rendering (views, ERB templates, asset pipeline)
2. **API-Only Rails Application**: Backend API service with separate frontend

### Business Requirements

- Provide weather forecast data to multiple client types (web, mobile, IoT devices)
- Integrate with third-party weather APIs (NWS, OpenWeatherMap)
- Support real-time weather updates via WebSockets
- Enable future expansion to different frontend technologies
- Maintain fast API response times
- Support multiple consumer applications

### Technical Considerations

**Modern Best Practices**:
- Frontend/backend separation is an established pattern in modern web development
- JavaScript frameworks (React, Vue, Angular, Svelte) excel at dynamic, interactive UIs
- API-first design enables multiple client types from a single backend
- Microservices and service-oriented architecture favor specialized services

**Rails Strengths**:
- Excellent for business logic and data processing
- Strong conventions for API development
- Robust ecosystem for integrations
- Built-in caching, background jobs, and WebSocket support
- API-only mode removes unnecessary overhead

**Frontend Requirements**:
- Weather data visualization benefits from rich JavaScript libraries
- Real-time updates require reactive UI frameworks
- Mobile apps need native or progressive web app support
- Different user segments may need different interfaces

## Decision

We will build **WeatherForecast as an API-only Rails 8 application** with clear frontend/backend separation.

### Architecture

**Backend (Rails API)**:
- Handle all business logic
- Manage third-party API integrations (NWS, OpenWeatherMap)
- Provide RESTful API endpoints
- Implement caching strategy with Redis
- Process and transform weather data
- Manage data persistence
- Handle authentication and authorization
- Provide WebSocket support via Action Cable

**Frontend (Separate JavaScript Application)**:
- Handle all UI rendering and user interactions
- Consume the Rails API
- Implement weather data visualization
- Manage client-side state
- Handle responsive design
- Support offline capabilities (PWA)

### Implementation Approach

**Rails Configuration**:
- Use `rails new --api` mode (already done)
- Remove view layer, asset pipeline, and frontend concerns
- Configure CORS for frontend access
- Optimize for API performance
- Focus on JSON API responses

**Frontend Options** (to be decided separately):
- React, Vue, Angular, or Svelte for web
- React Native or Flutter for mobile
- Progressive Web App for cross-platform

**Communication**:
- RESTful JSON API for primary communication
- Action Cable (WebSockets) for real-time weather updates
- Standard HTTP methods and status codes
- Versioned API endpoints (e.g., `/api/v1/forecasts`)

## Consequences

### Positive Consequences

1. **Flexibility**: Multiple frontend clients can consume the same API
   - Web application
   - Mobile applications (iOS, Android)
   - IoT devices
   - Third-party integrations

2. **Scalability**: Frontend and backend can scale independently
   - Deploy frontend to CDN for global distribution
   - Scale API servers based on traffic
   - Optimize each layer separately

3. **Development Efficiency**:
   - Frontend and backend teams can work independently
   - Clear separation of concerns
   - Easier to reason about each layer
   - Faster iteration on UI without backend changes

4. **Performance**:
   - No view rendering overhead in Rails
   - Client-side caching and state management
   - Faster API responses
   - Progressive loading of data

5. **Technology Choice**:
   - Can choose best frontend framework for the job
   - Can update frontend without Rails changes
   - Not locked into Rails view technologies

6. **Testing**:
   - API testing independent of UI testing
   - Clear API contract to test against
   - Easier to mock and stub in tests

7. **Rails Optimization**:
   - Smaller application footprint
   - Faster boot time
   - Reduced memory usage
   - Focus on API performance

### Negative Consequences

1. **Complexity**:
   - Two separate deployments to manage
   - More infrastructure to maintain
   - CORS configuration required
   - Authentication complexity (token-based vs session)

2. **Initial Setup**:
   - Need to set up separate frontend project
   - Configure build and deployment pipelines
   - Establish communication patterns
   - API versioning strategy from day one

3. **Development Workflow**:
   - Running two servers in development
   - Coordinating changes across frontend/backend
   - API documentation becomes critical
   - Need clear API contracts

4. **Learning Curve**:
   - Team needs frontend framework expertise
   - Different testing approaches for each layer
   - API design best practices
   - Security considerations for API endpoints

5. **Debugging**:
   - Issues may span frontend and backend
   - Network layer adds complexity
   - Need tools to inspect API calls
   - Logs distributed across systems

### Neutral Consequences

1. **API Documentation**: Must maintain clear API documentation (consider tools like OpenAPI/Swagger)
2. **Versioning**: Need API versioning strategy from start
3. **Security**: Token-based authentication (JWT, OAuth) vs session-based
4. **Deployment**: Separate deployment processes for frontend and backend

## Implementation Guidelines

### Rails API Best Practices

1. **API Versioning**: Use URL versioning (`/api/v1/`)
2. **JSON Structure**: Consistent response format
3. **Error Handling**: Meaningful error messages and HTTP status codes
4. **Rate Limiting**: Protect API from abuse
5. **Documentation**: OpenAPI/Swagger documentation
6. **CORS**: Configure for frontend domains
7. **Authentication**: Token-based (JWT or API keys)

### Frontend Integration

1. **API Client**: Centralized API client library
2. **Error Handling**: Graceful degradation for API errors
3. **Loading States**: Handle async API calls elegantly
4. **Caching**: Client-side caching of weather data
5. **Real-time**: WebSocket integration for updates

### Development Experience

1. **Local Development**: Both servers run concurrently
2. **API Documentation**: Keep documentation in sync with implementation
3. **API Testing**: Use tools like Postman or Insomnia
4. **Contract Testing**: Ensure frontend/backend compatibility

## Alternatives Considered

### 1. Monolithic Rails Application with Views

**Description**: Traditional Rails application with ERB/Hotwire for frontend

**Why Not Chosen**:
- Limited to single web interface
- Difficult to support mobile apps
- Mixing frontend/backend concerns
- Less flexible for future frontend changes
- Not optimal for API-heavy application
- Harder to scale frontend and backend independently

**When It Would Be Better**:
- Simple CRUD applications
- Team with limited frontend experience
- Rapid prototyping
- Internal tools with basic UI

### 2. Rails API with Hotwire/Turbo

**Description**: Rails API serving Hotwire/Turbo for reactive frontend

**Why Not Chosen**:
- Still couples frontend to Rails
- Less flexibility for native mobile apps
- Emerging technology with smaller ecosystem
- Team may be more familiar with React/Vue
- Harder to support multiple frontend types

**When It Would Be Better**:
- Want reactive UI without separate frontend
- Team wants to stay in Rails ecosystem
- Progressive enhancement approach
- Simpler deployment model

### 3. GraphQL API Instead of REST

**Description**: Use GraphQL instead of RESTful API

**Why Not Chosen**:
- REST is simpler and well-understood
- Weather data doesn't have complex relationship graphs
- REST caching is more straightforward
- Smaller learning curve
- Can add GraphQL later if needed

**When It Would Be Better**:
- Complex data relationships
- Clients need flexible queries
- Over-fetching is a problem
- Team has GraphQL expertise

## Related Decisions

- **ADR-0001**: Use Redis for Caching - Supports API performance goals
- **Future ADR**: Frontend Framework Selection
- **Future ADR**: Authentication Strategy (JWT vs OAuth)
- **Future ADR**: API Versioning Strategy

## References

- [Rails API-Only Applications Guide](https://guides.rubyonrails.org/api_app.html)
- [Best Practices for Building a RESTful API](https://www.vinaysahni.com/best-practices-for-a-pragmatic-restful-api)
- [Frontend/Backend Separation Benefits](https://www.thoughtworks.com/insights/blog/architecting-continuous-delivery)
- [API Design Patterns](https://swagger.io/resources/articles/best-practices-in-api-design/)

## Review Notes

This decision aligns with:
- Modern web development best practices
- Project requirement for multiple client types
- Scalability and performance goals
- Team's ability to work with JavaScript frameworks
- Industry trends toward API-first architecture

---

*Date*: 2025-10-10
*Author*: Architecture Team
*Reviewers*: Systems Architect, Rails Specialist, Domain Expert
*Related ADRs*: ADR-0001 (Redis Caching)
