# frozen_string_literal: true

# Circuit breaker configuration for BreakerMachines.
#
# In test mode: in-memory storage (fast, isolated per-example via registry.clear).
# In development/production: Rails.cache (Redis) so state is shared across
# all Falcon fibers and worker processes.
#
# Log events are suppressed in tests to keep RSpec output clean.
BreakerMachines.configure do |config|
  config.default_storage = Rails.env.test? ? :memory : :cache
  config.log_events      = !Rails.env.test?
end
