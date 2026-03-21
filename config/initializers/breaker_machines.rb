# frozen_string_literal: true

# Circuit breaker configuration for BreakerMachines.
#
# In test mode: in-memory storage (fast, isolated per-example via registry.clear).
# In development/production: Rails.cache (Redis) so state is shared across
# all Falcon fibers and worker processes.
#
# Log events are suppressed in tests to keep RSpec output clean.
BreakerMachines.configure do |config|
  # :memory and :bucket_memory are recognized Symbol shortcuts in BreakerMachines.
  # For the cache-backed store we must pass the class directly; passing :cache
  # is not a recognized shortcut and would leave @storage as a raw Symbol,
  # causing NoMethodError on `@storage.get_status` when the circuit initializes.
  config.default_storage = Rails.env.test? ? :memory : BreakerMachines::Storage::Cache
  config.log_events      = !Rails.env.test?
end
