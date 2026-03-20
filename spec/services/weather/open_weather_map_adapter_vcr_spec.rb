# frozen_string_literal: true

require "rails_helper"

# VCR-based integration tests for OpenWeatherMapAdapter.
# These specs replay recorded HTTP interactions — no real network calls are made.
# To re-record cassettes, change `record: :none` to `record: :new_episodes` in
# spec/support/vcr.rb and run with a valid OPENWEATHERMAP_API_KEY.

RSpec.describe Weather::OpenWeatherMapAdapter, :vcr, type: :service do
  let(:adapter) { described_class.new(api_key: "test_api_key") }

  describe "#current_weather" do
    context "by city name", vcr: { cassette_name: "openweathermap/current_weather_by_city" } do
      it "returns a Forecast with the correct location and temperature" do
        forecast = adapter.current_weather(location: "London")

        expect(forecast).to be_a(Weather::Forecast)
        expect(forecast.location).to eq("London")
        expect(forecast.temperature.celsius).to be_a(Float)
        expect(forecast.conditions).to eq("Clouds")
      end
    end

    context "by US zip code", vcr: { cassette_name: "openweathermap/current_weather_by_zip" } do
      it "returns a Forecast" do
        forecast = adapter.current_weather(location: "10001")

        expect(forecast).to be_a(Weather::Forecast)
        expect(forecast.conditions).to eq("Clear")
        expect(forecast.temperature.celsius).to be > 0
      end
    end

    context "by coordinates", vcr: { cassette_name: "openweathermap/current_weather_by_coords" } do
      it "returns a Forecast" do
        forecast = adapter.current_weather(location: "51.5074,-0.1278")

        expect(forecast).to be_a(Weather::Forecast)
        expect(forecast.location).to eq("London")
      end
    end

    context "when location is not found", vcr: { cassette_name: "openweathermap/location_not_found" } do
      it "raises LocationNotFoundError" do
        expect {
          adapter.current_weather(location: "InvalidCityXYZ999")
        }.to raise_error(Weather::BaseAdapter::LocationNotFoundError, /city not found/)
      end
    end

    context "when rate limited", vcr: { cassette_name: "openweathermap/rate_limited" } do
      it "raises RateLimitError" do
        expect {
          adapter.current_weather(location: "London")
        }.to raise_error(Weather::BaseAdapter::RateLimitError)
      end
    end
  end

  describe "#forecast" do
    context "for a city", vcr: { cassette_name: "openweathermap/forecast_5day_london" } do
      it "returns an array of Forecast objects" do
        forecasts = adapter.forecast(location: "London", days: 7)

        expect(forecasts).to be_an(Array)
        expect(forecasts).not_to be_empty
        expect(forecasts.first).to be_a(Weather::Forecast)
        expect(forecasts.first.location).to eq("London")
      end

      it "includes precipitation chance from pop field" do
        forecasts = adapter.forecast(location: "London", days: 7)

        # The cassette includes pop: 0.2 for the first entry
        expect(forecasts.first.precipitation_chance).to eq(20.0)
      end
    end
  end
end
