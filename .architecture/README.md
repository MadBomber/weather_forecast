# WeatherForecast API Architecture Documentation

This directory contains all architecture-related documentation for the WeatherForecast Rails API application.

## Directory Structure

```
.architecture/
├── README.md                 # This file
├── members.yml              # Architecture review team configuration
├── principles.md            # Core architectural principles
├── decisions/               # Architecture decisions directory
│   └── adrs/               # Architectural Decision Records
├── reviews/                # Architecture review documents
├── recalibration/          # Architecture recalibration sessions
├── comparisons/            # Technology and approach comparisons
├── docs/                   # Additional architecture documentation
└── templates/              # Templates for ADRs and other docs
```

## How to Use This Framework

### 1. Making Architectural Decisions

When making a significant architectural decision:

1. Create a new ADR using the template in `templates/adr-template.md`
2. Number it sequentially (e.g., `0001-use-redis-for-caching.md`)
3. Save it in `decisions/adrs/`
4. Follow the ADR format:
   - **Title**: Short, descriptive name
   - **Status**: Proposed, Accepted, Deprecated, or Superseded
   - **Context**: What problem are we solving?
   - **Decision**: What did we decide?
   - **Consequences**: What are the implications?

### 2. Requesting an Architecture Review

To get feedback from the AI architecture team:

1. Describe what you want reviewed (new feature, refactoring, etc.)
2. Ask your AI assistant: "I need an architecture review for [feature/change]"
3. The AI will convene the team defined in `members.yml`
4. Review will be saved in the `reviews/` directory

### 3. Architecture Team Members

The architecture review team is defined in `members.yml` and includes:

- **Systems Architect**: Overall system design and API architecture
- **Domain Expert**: Weather forecast domain modeling
- **Rails Specialist**: Rails best practices and patterns
- **Security Specialist**: Security implications and protections
- **Redis Specialist**: Caching strategies and Redis usage
- **Performance Specialist**: Performance optimization
- **Testing Specialist**: Test design and coverage

### 4. Guiding Principles

All architectural decisions should align with the principles documented in `principles.md`:

1. API-First Design
2. Performance Through Caching
3. Testable by Design
4. Debuggability with debug_me
5. Domain-Driven Design
6. Rails Conventions Over Configuration
7. Security by Default
8. Scalability Through Statelessness
9. Observable and Monitorable
10. Evolutionary Architecture

## Common Use Cases

### Example: Creating an ADR

```bash
# Copy the template
cp .architecture/templates/adr-template.md .architecture/decisions/adrs/0001-my-decision.md

# Edit the file with your decision details
# Commit to git
```

### Example: Requesting Review

In your AI coding assistant (Claude Code, Cursor, etc.):

```
I'm implementing a new endpoint to fetch 7-day weather forecasts.
Can the architecture team review my approach?

Here's what I'm planning:
- GET /api/v1/forecasts/:location
- Cache responses for 1 hour in Redis
- Pull data from external weather API
- Return JSON with forecast details
```

The AI will respond with perspectives from each team member.

### Example: Documenting a Technology Comparison

When evaluating alternatives, document them in `comparisons/`:

```markdown
# Redis vs Memcached for Weather Forecast Caching

## Context
Need to choose a caching solution...

## Options Evaluated
1. Redis
2. Memcached
3. SQLite (file-based cache)

## Decision
Redis (see ADR-0002)
```

## Best Practices

1. **Keep ADRs Short**: Focus on the decision, not implementation details
2. **Update Status**: Mark ADRs as Superseded when you make new decisions
3. **Link Related ADRs**: Reference other ADRs when relevant
4. **Review Regularly**: Revisit principles and decisions as the project evolves
5. **Involve the Team**: Use architecture reviews for significant changes

## Integration with AI Assistants

### Claude Code
Claude Code automatically understands this framework structure. Simply reference files or ask for reviews.

### Cursor
If using Cursor, ensure the `.architecture/` directory is included in your context.

### GitHub Copilot
Copilot can use these files for context when suggesting code.

## Questions?

Refer to the AI Software Architect framework documentation:
https://github.com/codenamev/ai-software-architect

---

*Last Updated*: 2025-10-10
