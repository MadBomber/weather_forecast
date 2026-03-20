# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rate limiting", type: :request do
  let(:mock_adapter) { instance_double(Weather::OpenWeatherMapAdapter) }
  let(:ip) { "1.2.3.4" }
  let(:memory_store) { ActiveSupport::Cache::MemoryStore.new }

  before do
    allow(Weather::OpenWeatherMapAdapter).to receive(:new).and_return(mock_adapter)
    allow(mock_adapter).to receive(:current_cache_key).with(location: anything).and_return("test_key")
    allow(mock_adapter).to receive(:current_weather).with(location: anything).and_return(
      Weather::Forecast.new(location: "London", timestamp: Time.current, temperature: { celsius: 15.0 }, conditions: "Clear")
    )
    # Use a real memory store so throttle counters actually increment
    Rack::Attack.cache.store = memory_store
    memory_store.clear
  end

  after do
    # Restore Rails.cache (null_store in test env) after each example
    Rack::Attack.cache.store = Rails.cache
  end

  describe "burst throttle (10 req / 10 seconds)" do
    it "allows requests up to the burst limit" do
      10.times do
        get "/api/v1/current", params: { location: "London" }, headers: { "REMOTE_ADDR" => ip }
        expect(response).not_to have_http_status(429)
      end
    end

    it "returns 429 JSON when burst limit is exceeded" do
      10.times { get "/api/v1/current", params: { location: "London" }, headers: { "REMOTE_ADDR" => ip } }

      get "/api/v1/current", params: { location: "London" }, headers: { "REMOTE_ADDR" => ip }

      expect(response).to have_http_status(429)
      expect(response.content_type).to include("application/json")
      json = JSON.parse(response.body)
      expect(json["error"]).to include("Rate limit exceeded")
      expect(json["retry_after"]).to be_present
    end

    it "includes Retry-After header when throttled" do
      11.times { get "/api/v1/current", params: { location: "London" }, headers: { "REMOTE_ADDR" => ip } }

      expect(response.headers["Retry-After"]).to be_present
    end
  end

  describe "different IPs are throttled independently" do
    it "does not throttle a different IP when one IP is at limit" do
      11.times { get "/api/v1/current", params: { location: "London" }, headers: { "REMOTE_ADDR" => ip } }
      expect(response).to have_http_status(429)

      get "/api/v1/current", params: { location: "London" }, headers: { "REMOTE_ADDR" => "9.9.9.9" }
      expect(response).not_to have_http_status(429)
    end
  end
end
