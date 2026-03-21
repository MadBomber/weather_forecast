# frozen_string_literal: true

require "rails_helper"

# Full-stack integration test covering the complete request lifecycle:
#
#   Auth → Rate limit → Controller → Cache miss/hit → Adapter → OWM API → Response
#
# A single VCR cassette records one HTTP interaction (the cache-miss fetch).
# Subsequent requests within the same example are served from the in-memory
# cache — no additional HTTP calls are made, and VCR does not interfere.
RSpec.describe "Weather forecast full-stack integration", type: :request do
  # The test environment uses NullStore, which discards every write.  Swap it
  # for a real MemoryStore so Rails.cache.fetch actually caches between calls
  # within the same example.  The let-memoised instance is shared across all
  # calls to Rails.cache inside the example.
  let(:memory_cache) { ActiveSupport::Cache::MemoryStore.new }

  before do
    allow(Rails).to receive(:cache).and_return(memory_cache)
  end

  describe "GET /api/v1/current", vcr: { cassette_name: "integration/current_london" } do
    let(:location) { "London" }

    context "when no API keys are configured (open / PoC mode)" do
      it "returns 200 with a normalised weather payload on a cache miss" do
        get "/api/v1/current", params: { location: location }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json.dig("data", "location")).to eq("London")
        expect(json.dig("data", "temperature", "celsius")).to be_a(Numeric)
        expect(json.dig("data", "conditions")).to be_present
        expect(json.dig("performance", "cached")).to be false
        expect(json.dig("performance", "duration_ms")).to be_a(Numeric)
      end

      it "serves the second request from cache and sets cached: true" do
        # First request — misses the cache; OWM cassette interaction is consumed.
        get "/api/v1/current", params: { location: location }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).dig("performance", "cached")).to be false

        # Second request — the MemoryStore now holds the result; no HTTP call is made.
        get "/api/v1/current", params: { location: location }
        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body).dig("performance", "cached")).to be true
      end
    end

    context "when API_KEYS env var is set" do
      around do |example|
        old = ENV["API_KEYS"]
        ENV["API_KEYS"] = "integration-test-key"
        example.run
      ensure
        ENV["API_KEYS"] = old
      end

      it "returns 401 when no X-API-Key header is supplied" do
        get "/api/v1/current", params: { location: location }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to include("Unauthorized")
      end

      it "returns 200 and weather data when the correct X-API-Key is supplied" do
        get "/api/v1/current",
            params: { location: location },
            headers: { "X-API-Key" => "integration-test-key" }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json.dig("data", "location")).to eq("London")
        expect(json.dig("performance", "cached")).to be false
      end

      it "returns 401 when an invalid X-API-Key is supplied" do
        get "/api/v1/current",
            params: { location: location },
            headers: { "X-API-Key" => "wrong-key" }

        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)["error"]).to include("Unauthorized")
      end
    end
  end
end
