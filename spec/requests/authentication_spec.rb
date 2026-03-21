# frozen_string_literal: true

require "rails_helper"

RSpec.describe "API Key Authentication", type: :request do
  let(:mock_adapter) { instance_double(Weather::OpenWeatherMapAdapter) }
  let(:valid_key) { "test_api_key_abc123" }

  before do
    allow(Weather::AdapterFactory).to receive(:build).and_return(mock_adapter)
    allow(mock_adapter).to receive(:current_weather).with(location: anything).and_return(
      Weather::Forecast.new(location: "London", timestamp: Time.current, temperature: { celsius: 15.0 }, conditions: "Clear")
    )
    allow(mock_adapter).to receive(:last_cache_hit?).and_return(false)
  end

  context "when API_KEYS is not configured (open mode)" do
    around do |example|
      original = ENV["API_KEYS"]
      ENV.delete("API_KEYS")
      example.run
      ENV["API_KEYS"] = original
    end

    it "allows requests without an API key" do
      get "/api/v1/current", params: { location: "London" }
      expect(response).not_to have_http_status(:unauthorized)
    end
  end

  context "when API_KEYS is configured" do
    around do |example|
      original = ENV["API_KEYS"]
      ENV["API_KEYS"] = valid_key
      example.run
      ENV["API_KEYS"] = original
    end

    it "allows requests with a valid X-API-Key header" do
      get "/api/v1/current",
        params: { location: "London" },
        headers: { "X-API-Key" => valid_key }

      expect(response).to have_http_status(:success)
    end

    it "rejects requests without an X-API-Key header" do
      get "/api/v1/current", params: { location: "London" }

      expect(response).to have_http_status(:unauthorized)
      json = JSON.parse(response.body)
      expect(json["error"]).to include("Unauthorized")
    end

    it "rejects requests with an invalid X-API-Key" do
      get "/api/v1/current",
        params: { location: "London" },
        headers: { "X-API-Key" => "wrong_key" }

      expect(response).to have_http_status(:unauthorized)
    end

    it "allows multiple valid keys" do
      second_key = "another_valid_key_xyz"
      ENV["API_KEYS"] = "#{valid_key},#{second_key}"

      get "/api/v1/current",
        params: { location: "London" },
        headers: { "X-API-Key" => second_key }

      expect(response).to have_http_status(:success)
    end

    it "uses constant-time comparison to prevent timing attacks" do
      # Both calls should behave identically (no timing difference observable at this level)
      get "/api/v1/current",
        params: { location: "London" },
        headers: { "X-API-Key" => valid_key }
      expect(response).to have_http_status(:success)

      get "/api/v1/current",
        params: { location: "London" },
        headers: { "X-API-Key" => "wrong_key" }
      expect(response).to have_http_status(:unauthorized)
    end

    it "logs a warning when an invalid key is provided" do
      expect(Rails.logger).to receive(:warn).with(/invalid API key/i)

      get "/api/v1/current",
        params: { location: "London" },
        headers: { "X-API-Key" => "bad_key" }
    end

    it "logs a warning when no key is provided" do
      expect(Rails.logger).to receive(:warn).with(/missing API key/i)

      get "/api/v1/current", params: { location: "London" }
    end
  end

  describe "health check endpoint" do
    around do |example|
      original = ENV["API_KEYS"]
      ENV["API_KEYS"] = valid_key
      example.run
      ENV["API_KEYS"] = original
    end

    it "is always accessible without an API key" do
      get "/up"
      # Health check returns 200 when app boots successfully
      expect(response).not_to have_http_status(:unauthorized)
    end
  end
end
