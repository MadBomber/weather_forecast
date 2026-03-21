# frozen_string_literal: true

require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/fixtures/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!

  # Scrub API key from recorded cassettes before committing
  config.filter_sensitive_data("<OWM_API_KEY>") { ENV.fetch("OPENWEATHERMAP_API_KEY", "test_api_key") }

  # Raise an error when a cassette is played back but the request doesn't match
  # any recorded interaction — prevents silently returning wrong data.
  config.default_cassette_options = {
    record: :none,           # Never make real HTTP requests; cassettes must exist
    match_requests_on: [ :method, :host, :path ]
  }
end
