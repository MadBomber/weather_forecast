# ADR-0006: Use RSpec for Testing Framework

## Status

Accepted

## Context

The WeatherForecast API requires a comprehensive testing strategy to ensure reliability, maintainability, and correctness. As a Rails 8 application, we need to choose between the two primary testing frameworks in the Ruby ecosystem:

1. **Minitest**: Rails default, simple, lightweight
2. **RSpec**: Feature-rich, behavior-driven development (BDD) focused

### Testing Requirements

**Current Needs**:
- Test weather API integration adapters
- Test caching behavior (Redis TTL, cache keys)
- Test API endpoints (controllers)
- Test value objects (Temperature, Forecast)
- Test service objects (weather data transformation)
- Mock external API calls (OpenWeatherMap, NWS)
- Test error handling and edge cases

**Quality Standards**:
- High test coverage (>80%)
- Clear, readable test descriptions
- Easy to test methods in isolation (per architectural principle)
- Support for mocking and stubbing external services
- Fast test execution
- Good developer experience

### Project Scale Expectations

**Current State**: Small project
- Limited models and services
- Few API endpoints
- Simple domain logic

**Expected Growth**: Large project
- Multiple weather providers (adapters)
- Complex caching strategies
- User management (future)
- Analytics and reporting (future)
- Multiple API versions
- Rich domain models
- Integration with additional services

**Trajectory**: The application is expected to grow from a proof-of-concept integration layer into a production-grade weather data platform with multiple consumers, complex business logic, and sophisticated caching strategies.

### Framework Comparison

#### Minitest

**Characteristics**:
- Rails default (included with Rails)
- Lightweight and fast
- Simple Ruby syntax
- Part of Ruby standard library
- Test::Unit style and spec style available
- Minimal DSL, closer to plain Ruby

**Pros**:
- No additional dependencies
- Faster execution (lighter framework)
- Simpler learning curve
- Less "magic" - plain Ruby
- Rails convention (default choice)
- Good for simple CRUD apps

**Cons**:
- Less expressive test descriptions
- Fewer built-in matchers
- Less sophisticated mocking/stubbing
- Smaller ecosystem of plugins
- Less documentation and community resources
- Harder to maintain in large codebases
- Less support for BDD approach

**Best For**:
- Small projects
- Simple applications
- Teams preferring minimal DSL
- Quick prototypes
- Developers who dislike "magic"

#### RSpec

**Characteristics**:
- BDD-focused framework
- Rich DSL for test descriptions
- Extensive matcher library
- Strong mocking/stubbing support (rspec-mocks)
- Large ecosystem (FactoryBot, VCR, etc.)
- Industry standard for larger Rails apps

**Pros**:
- **Expressive Tests**: `describe`, `context`, `it` create readable specs
- **Rich Matchers**: `expect(x).to eq(y)`, `change`, `raise_error`, etc.
- **Better Organization**: Nested contexts for complex scenarios
- **Mocking/Stubbing**: Sophisticated doubles and stubs
- **Ecosystem**: FactoryBot, VCR, Shoulda Matchers, etc.
- **Documentation**: Extensive community resources
- **BDD Approach**: Tests read like specifications
- **Scalability**: Maintains clarity in large codebases

**Cons**:
- Additional dependency
- Slightly slower than Minitest
- Steeper learning curve
- More "magic" with DSL
- Configuration overhead

**Best For**:
- Medium to large projects
- Complex business logic
- BDD approach preferred
- Teams valuing expressive tests
- Projects expected to scale

### Our Context

**Architectural Principles** (from `.architecture/principles.md`):
- **Testable by Design**: "Every method must be easily tested in isolation"
- **Code Quality**: High standards for maintainability
- **Professional Development**: Building production-grade software

**Project Expectations**:
- Starting small but expected to grow significantly
- Complex integrations (multiple weather providers)
- Sophisticated caching logic
- External API mocking critical
- Long-term maintenance expected

**Team Preferences**:
- Value clear, self-documenting code
- Prefer comprehensive test coverage
- BDD approach aligns with domain modeling
- Investment in quality over speed

## Decision

We will use **RSpec as the testing framework** for the WeatherForecast API.

### Rationale

**1. Expected Project Growth**
- Application is expected to evolve into a large, complex project
- Better to start with RSpec than migrate later
- RSpec scales better as codebase grows
- Investment pays off as complexity increases

**2. Complex Testing Scenarios**
- Weather API integration requires sophisticated mocking
- Multiple adapters need consistent, clear test structure
- Caching behavior requires expressive matchers
- External service mocking benefits from RSpec's features

**3. Readability and Maintainability**
- `describe`, `context`, `it` blocks create self-documenting tests
- Nested contexts organize complex scenarios clearly
- Tests serve as executable documentation
- Easier for new team members to understand

**4. Ecosystem and Tools**
- **FactoryBot**: Clean test data creation
- **VCR**: Record/replay HTTP interactions (perfect for weather APIs)
- **Shoulda Matchers**: Simplified Rails model testing
- **Database Cleaner**: Transaction management
- Extensive plugin ecosystem

**5. BDD Alignment**
- Domain-driven design principle (ADR principle #5)
- Tests describe behavior, not implementation
- Helps clarify requirements
- Better communication with stakeholders

**6. Industry Standard**
- Most large Rails applications use RSpec
- Abundant documentation and examples
- Easy to hire developers familiar with RSpec
- Best practices well-established

**7. Mocking External APIs**
- Critical for testing OpenWeatherMap/NWS integrations
- RSpec mocks and stubs are powerful
- VCR integration excellent
- Easy to test error scenarios

### Implementation Strategy

**Phase 1: Setup**
```ruby
# Gemfile (already included)
group :test do
  gem 'rspec-rails'
end

# Install
bundle install
rails generate rspec:install
```

**Phase 2: Configuration**
```ruby
# spec/spec_helper.rb
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
```

**Phase 3: Add Supporting Gems**
```ruby
group :test do
  gem 'rspec-rails'
  gem 'factory_bot_rails'    # Test data factories
  gem 'faker'                # Fake data generation
  gem 'vcr'                  # Record HTTP interactions
  gem 'webmock'              # Stub HTTP requests
  gem 'shoulda-matchers'     # Rails matchers
end
```

### Testing Patterns

**1. Service Objects**:
```ruby
# spec/services/weather/openweathermap_adapter_spec.rb
require 'rails_helper'

RSpec.describe Weather::OpenweathermapAdapter do
  describe '#current_weather' do
    let(:adapter) { described_class.new(api_key: 'test_key') }
    let(:zipcode) { '10001' }

    context 'when API call succeeds' do
      it 'returns Weather::Forecast object' do
        VCR.use_cassette('openweathermap/current_weather_success') do
          result = adapter.current_weather(location: zipcode)
          expect(result).to be_a(Weather::Forecast)
          expect(result.location).to eq(zipcode)
        end
      end

      it 'caches the result for 30 minutes' do
        expect(Rails.cache).to receive(:write)
          .with(anything, anything, expires_in: 30.minutes)

        adapter.current_weather(location: zipcode)
      end
    end

    context 'when location is not found' do
      it 'raises LocationNotFoundError' do
        VCR.use_cassette('openweathermap/location_not_found') do
          expect {
            adapter.current_weather(location: 'INVALID')
          }.to raise_error(Weather::BaseAdapter::LocationNotFoundError)
        end
      end
    end

    context 'when rate limited' do
      it 'raises RateLimitError' do
        VCR.use_cassette('openweathermap/rate_limited') do
          expect {
            adapter.current_weather(location: zipcode)
          }.to raise_error(Weather::BaseAdapter::RateLimitError)
        end
      end
    end
  end
end
```

**2. Value Objects**:
```ruby
# spec/models/weather/temperature_spec.rb
require 'rails_helper'

RSpec.describe Weather::Temperature do
  describe '#initialize' do
    context 'with celsius' do
      subject { described_class.new(celsius: 25) }

      it { is_expected.to have_attributes(celsius: 25.0) }

      it 'converts to fahrenheit' do
        expect(subject.fahrenheit).to be_within(0.1).of(77.0)
      end
    end

    context 'with fahrenheit' do
      subject { described_class.new(fahrenheit: 77) }

      it 'converts to celsius' do
        expect(subject.celsius).to be_within(0.1).of(25.0)
      end
    end
  end

  describe '#<=>' do
    let(:temp1) { described_class.new(celsius: 20) }
    let(:temp2) { described_class.new(celsius: 25) }

    it 'compares temperatures correctly' do
      expect(temp1).to be < temp2
      expect(temp2).to be > temp1
    end
  end
end
```

**3. Controllers**:
```ruby
# spec/controllers/api/v1/forecasts_controller_spec.rb
require 'rails_helper'

RSpec.describe Api::V1::ForecastsController, type: :controller do
  describe 'GET #show' do
    let(:zipcode) { '10001' }
    let(:forecast_data) {
      instance_double(Weather::Forecast, to_json: '{"temp": 72}')
    }

    before do
      allow_any_instance_of(Weather::OpenweathermapAdapter)
        .to receive(:current_weather)
        .with(location: zipcode)
        .and_return(forecast_data)
    end

    it 'returns forecast data' do
      get :show, params: { location: zipcode }

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include('application/json')
    end

    context 'when location not found' do
      before do
        allow_any_instance_of(Weather::OpenweathermapAdapter)
          .to receive(:current_weather)
          .and_raise(Weather::BaseAdapter::LocationNotFoundError)
      end

      it 'returns 404' do
        get :show, params: { location: 'INVALID' }
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
```

## Consequences

### Positive Consequences

1. **Scalability**:
   - RSpec maintains clarity as codebase grows
   - Nested contexts organize complex scenarios
   - Easier to maintain large test suites

2. **Readability**:
   - Tests read like specifications
   - Self-documenting test descriptions
   - Clear intent with `describe`, `context`, `it`

3. **Expressiveness**:
   - Rich matcher library
   - Custom matchers easy to create
   - Complex expectations simple to write

4. **External API Testing**:
   - VCR integration for recording HTTP interactions
   - Easy to mock OpenWeatherMap/NWS APIs
   - Comprehensive stubbing for error scenarios

5. **Ecosystem**:
   - FactoryBot for test data
   - Shoulda Matchers for Rails
   - Active community and plugins
   - Extensive documentation

6. **BDD Approach**:
   - Tests document expected behavior
   - Aligns with domain-driven design
   - Encourages thinking about requirements

7. **Team Onboarding**:
   - Industry standard (familiar to most Rails devs)
   - Abundant learning resources
   - Clear conventions and patterns

8. **Future-Proof**:
   - Right choice for expected project growth
   - Avoid migration pain later
   - Investment pays off as complexity increases

### Negative Consequences

1. **Additional Dependency**:
   - Not Rails default (Minitest is)
   - Requires explicit gem inclusion
   - Slightly larger dependency footprint

2. **Performance**:
   - Slightly slower than Minitest
   - More framework overhead
   - Marginal difference in practice

3. **Learning Curve**:
   - More concepts to learn (describe, context, let, etc.)
   - DSL can be confusing initially
   - More "magic" than plain Ruby

4. **Configuration**:
   - More setup required
   - Need to configure RSpec, FactoryBot, VCR, etc.
   - More files in spec/ directory

5. **Opinionated**:
   - Specific way of structuring tests
   - More conventions to follow
   - Less flexibility in test organization

### Neutral Consequences

1. **Convention**: Establishes RSpec as team standard
2. **Documentation**: Tests serve as specs for features
3. **Consistency**: All tests follow same patterns

## Alternatives Considered

### 1. Minitest (Rails Default)

**Why Not Chosen**:
- **Project Scale**: Expected to grow beyond Minitest's sweet spot
- **Expressiveness**: Less readable for complex scenarios
- **Ecosystem**: Smaller plugin ecosystem
- **Mocking**: Less sophisticated than RSpec
- **Migration Cost**: Switching from Minitest to RSpec later is painful

**When It Would Be Better**:
- Small, simple CRUD applications
- Team strongly prefers minimal DSL
- No expectation of significant growth
- Performance critical (marginal advantage)

**Acknowledgment**: Minitest is excellent for small projects and has valid use cases. Our decision is based on expected project growth, not inherent superiority of either framework.

### 2. Both (Minitest for Simple, RSpec for Complex)

**Description**: Use Minitest for simple tests, RSpec for complex ones

**Why Not Chosen**:
- **Inconsistency**: Confusing to have two testing styles
- **Cognitive Load**: Team must know both frameworks
- **Tooling**: Different configurations and helpers
- **Maintenance**: Harder to maintain mixed test suite

**When It Would Be Better**:
- Never - consistency is more valuable

### 3. Test::Unit (Minitest Predecessor)

**Description**: Original Rails testing framework

**Why Not Chosen**:
- **Deprecated**: Replaced by Minitest
- **Legacy**: No reason to use over Minitest or RSpec
- **No Advantages**: Strictly inferior to modern options

## Implementation Guidelines

### Setup

```bash
# Generate RSpec configuration
rails generate rspec:install

# Generate spec for model
rails generate rspec:model Forecast

# Generate spec for controller
rails generate rspec:controller Api::V1::Forecasts
```

### Configuration

```ruby
# spec/rails_helper.rb
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("Rails is running in production!") if Rails.env.production?
require 'rspec/rails'

# Load support files
Dir[Rails.root.join('spec', 'support', '**', '*.rb')].sort.each { |f| require f }

RSpec.configure do |config|
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  # Include FactoryBot methods
  config.include FactoryBot::Syntax::Methods
end
```

### VCR Configuration (for External APIs)

```ruby
# spec/support/vcr.rb
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/fixtures/vcr_cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.filter_sensitive_data('<OPENWEATHERMAP_API_KEY>') { ENV['OPENWEATHERMAP_API_KEY'] }
  c.filter_sensitive_data('<NWS_USER_AGENT>') { ENV['NWS_USER_AGENT'] }
end
```

### Test Organization

```
spec/
├── models/
│   └── weather/
│       ├── temperature_spec.rb
│       └── forecast_spec.rb
├── services/
│   └── weather/
│       ├── base_adapter_spec.rb
│       ├── openweathermap_adapter_spec.rb
│       └── nws_adapter_spec.rb
├── controllers/
│   └── api/
│       └── v1/
│           └── forecasts_controller_spec.rb
├── support/
│   ├── vcr.rb
│   └── factory_bot.rb
└── fixtures/
    └── vcr_cassettes/
```

## Success Metrics

1. **Test Coverage**: Maintain >80% coverage
2. **Test Readability**: Tests serve as documentation
3. **External API Mocking**: 100% of external calls mocked/recorded
4. **Test Speed**: Full suite < 30 seconds
5. **Developer Experience**: Positive team feedback on RSpec

## Related Decisions

- **Architectural Principle #3**: Testable by Design - RSpec supports testing in isolation
- **ADR-0001**: Redis caching - Need to test TTL behavior with RSpec matchers
- **ADR-0004**: OpenWeatherMap - VCR integration critical for API testing

## References

- [RSpec Documentation](https://rspec.info/)
- [RSpec Rails](https://github.com/rspec/rspec-rails)
- [Better Specs](https://www.betterspecs.org/)
- [Effective Testing with RSpec 3](https://pragprog.com/titles/rspec3/effective-testing-with-rspec-3/)
- [VCR Gem](https://github.com/vcr/vcr)
- [FactoryBot](https://github.com/thoughtbot/factory_bot)

## Review Notes

This decision reflects:
- **Forward Thinking**: Choosing framework appropriate for expected scale
- **Quality Focus**: Investment in maintainable, readable tests
- **Pragmatism**: Acknowledging Minitest is fine for small projects, but we expect growth
- **Ecosystem**: Leveraging rich RSpec ecosystem for external API testing
- **Standards**: Following industry best practices for large Rails applications

**Key Principle**: "Minitest is preferred for small projects, but RSpec is preferred for larger projects. The expectation is that this application will turn into a large project."

---

*Date*: 2025-10-10
*Author*: Architecture Team
*Reviewers*: Testing Specialist, Rails Specialist, Systems Architect
*Related ADRs*: Architectural Principles (Testable by Design), ADR-0001 (Redis), ADR-0004 (OpenWeatherMap)
*Status*: Accepted - RSpec selected for expected project growth
