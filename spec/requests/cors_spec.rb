# frozen_string_literal: true

require "rails_helper"

RSpec.describe "CORS headers", type: :request do
  let(:mock_adapter) { instance_double(Weather::OpenWeatherMapAdapter) }
  let(:origin) { "https://example.com" }

  before do
    allow(Weather::AdapterFactory).to receive(:build).and_return(mock_adapter)
    allow(mock_adapter).to receive(:current_weather).with(location: anything).and_return(
      Weather::Forecast.new(location: "London", timestamp: Time.current, temperature: { celsius: 15.0 }, conditions: "Clear")
    )
    allow(mock_adapter).to receive(:last_cache_hit?).and_return(false)
  end

  describe "preflight OPTIONS request" do
    it "responds to OPTIONS with CORS headers" do
      options "/api/v1/current",
        headers: {
          "Origin" => origin,
          "Access-Control-Request-Method" => "GET",
          "Access-Control-Request-Headers" => "Content-Type"
        }

      expect(response.headers["Access-Control-Allow-Origin"]).to be_present
    end
  end

  describe "GET request from allowed origin" do
    it "includes Access-Control-Allow-Origin header" do
      get "/api/v1/current",
        params: { location: "London" },
        headers: { "Origin" => origin }

      expect(response).to have_http_status(:success)
      expect(response.headers["Access-Control-Allow-Origin"]).to be_present
    end
  end

  describe "with CORS_ALLOWED_ORIGINS restriction" do
    around do |example|
      original = ENV["CORS_ALLOWED_ORIGINS"]
      ENV["CORS_ALLOWED_ORIGINS"] = "https://allowed.com"
      example.run
      ENV["CORS_ALLOWED_ORIGINS"] = original
    end

    it "allows requests from an allowed origin" do
      get "/api/v1/current",
        params: { location: "London" },
        headers: { "Origin" => "https://allowed.com" }

      expect(response.headers["Access-Control-Allow-Origin"]).to eq("https://allowed.com")
    end

    it "does not set CORS header for a disallowed origin" do
      get "/api/v1/current",
        params: { location: "London" },
        headers: { "Origin" => "https://not-allowed.com" }

      expect(response.headers["Access-Control-Allow-Origin"]).to be_nil
    end
  end
end
