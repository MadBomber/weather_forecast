# ADR-0009: Use Environment Variables for API Keys and Credentials

## Status

Accepted

## Context

The WeatherForecast API requires secure storage and access to sensitive credentials including:
- OpenWeatherMap API key
- Redis connection string (may contain password)
- Future API keys (NWS user agent, geocoding services, etc.)
- Application secrets (session keys, etc.)

Rails provides multiple mechanisms for managing secrets and credentials:

### Option 1: Rails Encrypted Credentials (Rails 5.2+)

**Description**: Rails built-in encrypted credentials system

**Mechanism**:
- Encrypted file: `config/credentials.yml.enc`
- Master key: `config/master.key` (gitignored)
- Edit with: `rails credentials:edit`
- Access with: `Rails.application.credentials.openweathermap_api_key`

**Structure**:
```yaml
# config/credentials.yml.enc (encrypted)
openweathermap:
  api_key: abc123xyz

redis:
  url: redis://localhost:6379/0

secret_key_base: <generated>
```

**Features**:
- Encrypted at rest
- Version controlled (encrypted file)
- Environment-specific credentials
- Built into Rails
- Managed via `rails credentials:edit`

**Workflow**:
```bash
# Edit credentials
EDITOR=vim rails credentials:edit

# Deploy with master key
# Set RAILS_MASTER_KEY environment variable in production
```

### Option 2: Environment Variables

**Description**: Store secrets in system environment variables

**Mechanism**:
- Environment variables set in shell/system
- Load via `.env` file in development (with dotenv gem)
- Access with: `ENV['OPENWEATHERMAP_API_KEY']`
- Production: Set in hosting platform/container/system

**Structure**:
```bash
# .env (gitignored, development only)
OPENWEATHERMAP_API_KEY=abc123xyz
REDIS_URL=redis://localhost:6379/0
RAILS_ENV=development
```

**Features**:
- Simple and straightforward
- Platform-agnostic (12-factor app)
- Easy to override per environment
- No encryption needed
- Standard across languages/frameworks

**Workflow**:
```bash
# Development: Use .env file
echo "OPENWEATHERMAP_API_KEY=abc123" > .env

# Production: Set in hosting platform
heroku config:set OPENWEATHERMAP_API_KEY=abc123
# or
export OPENWEATHERMAP_API_KEY=abc123
```

### Option 3: Rails Secrets (Rails 4.1-5.1, deprecated)

**Description**: Original Rails secrets system (YAML file)

**Status**: Deprecated in favor of credentials

**Not Considered**: Superseded by encrypted credentials

### Project Context

**Current Stage**: Proof of Concept
- Rapid development and iteration
- Small team or solo developer
- Frequent credential changes during development
- Need to test with different API keys
- Quick setup critical
- Not production-scale yet

**Expected Evolution**:
- Start as PoC
- Evolve to production
- May need multiple environments
- Team may grow

**Complexity Factors**:
- Rails encrypted credentials adds cognitive overhead
- Need to share master key securely
- Editing credentials requires special command
- PoC stage doesn't need encryption complexity
- Environment variables are familiar and simple

### Comparison

| Feature | Encrypted Credentials | Environment Variables |
|---------|----------------------|----------------------|
| Setup Time | Medium (generate keys) | Fast (create .env) |
| Learning Curve | Medium (Rails-specific) | Low (universal) |
| Ease of Use | Medium (special editor) | High (plain text) |
| Version Control | Yes (encrypted) | No (gitignored) |
| Encryption | Yes | No (relies on system) |
| Platform Support | Rails-specific | Universal |
| Team Sharing | Need master key | Each dev sets own |
| PoC-Friendly | No | **Yes** |
| Production-Ready | Yes | **Yes** |
| 12-Factor App | Partial | **Yes** |
| Override Ease | Medium | **High** |

## Decision

We will use **environment variables** to store API keys and credentials for the WeatherForecast API, managed via the **dotenv-rails** gem in development.

### Rationale

**1. Proof of Concept Stage**
- **Simplicity**: PoC needs rapid iteration, not encryption overhead
- **Flexibility**: Easy to test different API keys
- **No Setup Complexity**: Just create .env file and go
- **Familiar**: Standard pattern across all languages/frameworks
- **Less Magic**: No special Rails commands needed

**2. Developer Experience**
- **Easy to Use**: Plain text file in development
- **No Special Commands**: No `EDITOR=vim rails credentials:edit`
- **Fast Iteration**: Change key and restart - no encryption steps
- **Universal Knowledge**: All developers understand environment variables
- **Debugging**: Easy to verify values with `ENV.inspect`

**3. Platform Agnostic**
- **12-Factor App**: Follows 12-factor methodology
- **Portable**: Works on any platform (Heroku, Docker, AWS, etc.)
- **No Vendor Lock-in**: Not Rails-specific
- **Container-Friendly**: Docker/Kubernetes standard
- **CI/CD Easy**: Standard in all CI systems

**4. Operational Simplicity**
- **No Master Key Management**: No need to share/secure master.key
- **Easy Deployment**: Set env vars in hosting platform
- **Override Friendly**: Easy to override per environment
- **No Migration Pain**: Moving between encrypted/env is harder than staying with env

**5. PoC Priorities**
- **Speed > Security (initially)**: PoC doesn't handle real user data
- **Flexibility > Structure**: Need to experiment with different providers
- **Simplicity > Features**: Don't need version-controlled secrets yet
- **Pragmatic**: Right tool for current stage

**6. Future Path**
- Can migrate to encrypted credentials later if needed
- Start simple, add complexity when justified
- Most successful projects stay with env vars
- Security handled at infrastructure level (secret managers)

### When to Revisit

**Consider Encrypted Credentials When**:
- Production deployment with sensitive user data
- Need to version control secrets (with encryption)
- Team grows and needs standardized secret management
- Compliance requires encrypted secrets at rest
- Security requirements increase

**Consider Secret Manager (AWS Secrets Manager, Vault) When**:
- Large-scale production deployment
- Multiple services sharing secrets
- Advanced rotation requirements
- Enterprise security requirements

### Implementation

**Setup**:
```ruby
# Gemfile
gem 'dotenv-rails', groups: [:development, :test]
```

```bash
# Install
bundle install

# Create .env file (gitignored)
cat > .env << 'EOF'
# Weather API Credentials
OPENWEATHERMAP_API_KEY=your_api_key_here
NWS_USER_AGENT=WeatherForecast/1.0

# Redis
REDIS_URL=redis://localhost:6379/0

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=generated_key_here
EOF

# Ensure .env is gitignored
echo ".env" >> .gitignore
echo ".env.local" >> .gitignore
```

**Access in Code**:
```ruby
# app/services/weather/openweathermap_adapter.rb
class Weather::OpenweathermapAdapter < Weather::BaseAdapter
  def initialize(api_key: nil)
    @api_key = api_key || ENV['OPENWEATHERMAP_API_KEY']

    unless @api_key
      raise ArgumentError, "OpenWeatherMap API key required. Set OPENWEATHERMAP_API_KEY environment variable."
    end
  end
end
```

**Configuration**:
```ruby
# config/environments/development.rb
config.cache_store = :redis_cache_store, {
  url: ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
}
```

**Testing**:
```ruby
# spec/support/env_helper.rb
RSpec.configure do |config|
  config.before(:each) do
    # Set test API keys
    ENV['OPENWEATHERMAP_API_KEY'] = 'test_api_key'
  end
end
```

**Production**:
```bash
# Heroku
heroku config:set OPENWEATHERMAP_API_KEY=abc123

# Docker
docker run -e OPENWEATHERMAP_API_KEY=abc123 weather-forecast

# Kubernetes
# Use ConfigMap or Secret

# AWS ECS
# Use environment variables in task definition
```

### Security Guidelines

**Development**:
- Never commit .env to version control
- Each developer uses own API keys (free tier)
- .env.example documents required variables (no actual values)

**Production**:
- Use hosting platform's secret management
- Rotate keys regularly
- Restrict access to production environment
- Monitor for leaked keys
- Use different keys per environment

**.env.example Template**:
```bash
# .env.example (committed to git as documentation)
# Copy to .env and fill in actual values

# Weather API Keys
OPENWEATHERMAP_API_KEY=your_openweathermap_key_here

# Redis Connection
REDIS_URL=redis://localhost:6379/0

# Application
RAILS_ENV=development
SECRET_KEY_BASE=generate_with_rails_secret
```

## Consequences

### Positive Consequences

1. **Simplicity**:
   - Easy to understand and use
   - No learning curve
   - Plain text editing (development)
   - Fast setup

2. **Flexibility**:
   - Easy to change keys during development
   - Test with different API keys quickly
   - Override per environment trivially
   - No encryption/decryption overhead

3. **Platform Agnostic**:
   - Works everywhere (Heroku, Docker, AWS, etc.)
   - 12-factor app compliant
   - Standard across languages
   - CI/CD friendly

4. **Developer Experience**:
   - No special Rails commands
   - Familiar pattern
   - Easy debugging
   - Quick iteration

5. **PoC Friendly**:
   - Minimal setup time
   - Focus on building, not infrastructure
   - Change credentials easily
   - Perfect for experimentation

6. **No Master Key Management**:
   - No master.key to secure and share
   - No risk of losing master key
   - Each developer manages own keys
   - Simpler team onboarding

7. **Production Ready**:
   - Works in production (via platform env vars)
   - Industry standard approach
   - Secure when using platform secret managers
   - Proven at scale

### Negative Consequences

1. **No Encryption at Rest** (Development):
   - .env file is plain text
   - Visible in editor
   - Could be accidentally committed
   - Relies on gitignore

2. **Not Version Controlled**:
   - Can't track secret changes in git
   - No history of credential updates
   - Must communicate changes out-of-band
   - Team members have different .env files

3. **Manual Synchronization**:
   - Each developer configures own .env
   - Need to communicate required variables
   - .env.example can get stale
   - No central source of truth

4. **Potential for Leaks**:
   - Could accidentally log ENV values
   - Could commit .env if gitignore fails
   - Could share .env in chat/email
   - Requires developer discipline

5. **Less Structure**:
   - No enforced schema
   - Typos in variable names
   - Missing required variables not caught early
   - No Rails-specific organization

### Neutral Consequences

1. **Industry Standard**: Following widespread practice
2. **Migration Path**: Can move to encrypted credentials later if needed
3. **Documentation**: .env.example serves as documentation

## Guidelines and Best Practices

### Development Setup

**Initial Setup**:
```bash
# 1. Copy example file
cp .env.example .env

# 2. Get API keys
# - OpenWeatherMap: https://openweathermap.org/api
# - Save in .env

# 3. Generate Rails secret
rails secret  # Copy output to SECRET_KEY_BASE in .env

# 4. Start application
rails server  # Automatically loads .env
```

### Security Best Practices

**Do**:
- ✅ Always gitignore .env files
- ✅ Use .env.example for documentation
- ✅ Use different keys per environment
- ✅ Rotate keys regularly
- ✅ Check for ENV key existence in code
- ✅ Use free-tier keys in development
- ✅ Monitor for leaked keys (GitHub secret scanning)

**Don't**:
- ❌ Commit .env to version control
- ❌ Share .env files via email/chat
- ❌ Log environment variable values
- ❌ Use production keys in development
- ❌ Hardcode fallback values for secrets
- ❌ Copy .env from production to laptop

### Code Patterns

**Require Environment Variables**:
```ruby
# Fail fast if required variable missing
def required_env(key)
  ENV.fetch(key) do
    raise "Missing required environment variable: #{key}"
  end
end

api_key = required_env('OPENWEATHERMAP_API_KEY')
```

**With Defaults (Non-Secrets)**:
```ruby
# Default for non-sensitive values
redis_url = ENV.fetch('REDIS_URL', 'redis://localhost:6379/0')
```

**Never Log Secrets**:
```ruby
# Bad
Rails.logger.info "Using API key: #{ENV['OPENWEATHERMAP_API_KEY']}"

# Good
Rails.logger.info "OpenWeatherMap API configured: #{ENV['OPENWEATHERMAP_API_KEY'].present?}"
```

### Testing

**Test Configuration**:
```ruby
# spec/rails_helper.rb
RSpec.configure do |config|
  config.before(:suite) do
    # Set test environment variables
    ENV['OPENWEATHERMAP_API_KEY'] = 'test_key_12345'
    ENV['REDIS_URL'] = 'redis://localhost:6379/1'  # Different DB for tests
  end
end
```

**Factory Pattern**:
```ruby
# spec/factories/adapters.rb
FactoryBot.define do
  factory :openweathermap_adapter, class: 'Weather::OpenweathermapAdapter' do
    initialize_with { new(api_key: ENV['OPENWEATHERMAP_API_KEY']) }
  end
end
```

## Required Environment Variables

**Development**:
```bash
OPENWEATHERMAP_API_KEY=<your_key>     # Required
REDIS_URL=redis://localhost:6379/0    # Optional (default shown)
RAILS_ENV=development                  # Optional (default shown)
SECRET_KEY_BASE=<generated_secret>     # Required
```

**Test**:
```bash
OPENWEATHERMAP_API_KEY=test_key       # Can be dummy value
REDIS_URL=redis://localhost:6379/1    # Different DB from dev
RAILS_ENV=test                        # Required
```

**Production**:
```bash
OPENWEATHERMAP_API_KEY=<prod_key>     # Required
REDIS_URL=<production_redis>          # Required
RAILS_ENV=production                  # Required
SECRET_KEY_BASE=<secure_secret>       # Required
RAILS_SERVE_STATIC_FILES=true         # If needed
RAILS_LOG_TO_STDOUT=true              # If needed
```

## Migration Path (Future)

**If Encrypted Credentials Become Necessary**:

```bash
# 1. Create encrypted credentials
rails credentials:edit

# 2. Migrate values from .env
# Copy API keys to credentials.yml.enc

# 3. Update code
# Before:
ENV['OPENWEATHERMAP_API_KEY']

# After:
Rails.application.credentials.openweathermap_api_key

# 4. Remove .env (gradually)
# Keep for local overrides during transition

# 5. Deploy with RAILS_MASTER_KEY
```

**Recommendation**: Only migrate if:
- Production security requirements demand it
- Team grows and needs centralized management
- Compliance requires encrypted secrets
- Benefits outweigh complexity

## Alternatives Considered

### 1. Rails Encrypted Credentials

**Why Not Chosen**:
- **Too Complex for PoC**: Adds unnecessary overhead
- **Slower Iteration**: Edit cycle more cumbersome
- **Master Key Management**: Extra complexity for small team
- **Not PoC-Appropriate**: Premature for current stage
- **Can Add Later**: Migration path exists if needed

**When It Would Be Better**:
- Production with sensitive user data
- Team needs centralized secret management
- Security compliance requirements
- Need version-controlled secrets

### 2. Hashicorp Vault / AWS Secrets Manager

**Description**: Enterprise secret management systems

**Why Not Chosen**:
- **Massive Overkill**: Far too complex for PoC
- **Infrastructure Overhead**: Extra services to run/pay for
- **Learning Curve**: Significant time investment
- **Not Appropriate**: For large-scale production only

**When It Would Be Better**:
- Large production deployment
- Multiple services sharing secrets
- Advanced rotation requirements
- Enterprise security requirements
- Compliance mandates

### 3. Hardcoded (Development Only)

**Description**: Hardcode API keys in code

**Why Not Chosen**:
- **Security Risk**: Could accidentally commit
- **Inflexible**: Can't change without code changes
- **Bad Practice**: Establishes poor patterns
- **Not Scalable**: Doesn't work for production

**When It Would Be Better**:
- Never - always use env vars at minimum

### 4. Mix (Env Vars + Credentials)

**Description**: Use both systems simultaneously

**Why Not Chosen**:
- **Confusing**: Where to look for secrets?
- **Inconsistent**: No clear pattern
- **Maintenance Burden**: Two systems to manage
- **Complexity**: Worse than either alone

**When It Would Be Better**:
- Migration period only (temporary)

## Related Decisions

- **ADR-0004**: OpenWeatherMap - Requires API key storage
- **ADR-0001**: Redis - May require connection string with password
- **ADR-0005**: No Database - Simplifies secret requirements

## References

- [The Twelve-Factor App - Config](https://12factor.net/config)
- [dotenv-rails Gem](https://github.com/bkeepers/dotenv)
- [Rails Encrypted Credentials](https://guides.rubyonrails.org/security.html#custom-credentials)
- [Environment Variables Best Practices](https://www.doppler.com/blog/environment-variables-best-practices)
- [GitHub Secret Scanning](https://docs.github.com/en/code-security/secret-scanning)

## Review Notes

This decision reflects:
- **Pragmatism**: Right tool for PoC stage
- **Simplicity**: Minimize overhead during rapid development
- **Standard Practice**: Following 12-factor app methodology
- **Flexibility**: Easy to change as project evolves
- **Developer Experience**: Prioritize ease of use
- **Migration Path**: Can adopt encryption later if needed

**Key Principle**: "It's just easier to work with on a proof of concept application." Acknowledge that encrypted credentials are valuable for production, but env vars are the right choice for current PoC stage.

**Honest Assessment**: This is a pragmatic choice for rapid development. If the project grows to production scale with sensitive data, we may revisit and adopt Rails encrypted credentials or a dedicated secret manager. For now, simplicity wins.

---

*Date*: 2025-10-10
*Author*: Lead Engineer, Architecture Team
*Reviewers*: Systems Architect, Security Specialist
*Related ADRs*: ADR-0004 (OpenWeatherMap), ADR-0001 (Redis)
*Status*: Accepted - Environment variables for PoC stage
*Review Trigger*: Revisit before production deployment with real user data
*Migration Path*: Can move to encrypted credentials if security requirements increase
