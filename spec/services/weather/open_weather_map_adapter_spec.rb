# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::OpenWeatherMapAdapter, type: :service do
  let(:api_key) { "test_api_key_123" }
  let(:adapter) { described_class.new(api_key: api_key) }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("OPENWEATHERMAP_API_KEY", nil).and_return(api_key)
  end

  describe "#initialize" do
    it "creates adapter with API key" do
      expect(adapter).to be_configured
    end

    it "uses environment variable for API key" do
      adapter = described_class.new
      expect(adapter).to be_configured
    end
  end

  describe "#current_weather" do
    let(:api_response) do
      {
        "name" => "London",
        "dt" => Time.current.to_i,
        "main" => {
          "temp" => 15.5,
          "humidity" => 72
        },
        "weather" => [
          {
            "main" => "Clouds",
            "description" => "partly cloudy"
          }
        ],
        "wind" => {
          "speed" => 12.5,
          "deg" => 315
        }
      }
    end

    context "with successful API call" do
      before do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/weather})
          .to_return(status: 200, body: api_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "returns forecast object" do
        forecast = adapter.current_weather(location: "London")

        expect(forecast).to be_a(Weather::Forecast)
        expect(forecast.location).to eq("London")
        expect(forecast.conditions).to eq("Clouds")
        expect(forecast.temperature.celsius).to eq(15.5)
      end

      it "caches the result" do
        cache_key = adapter.send(:cache_key, location: "London", type: :current)

        expect(Rails.cache).to receive(:fetch).with(cache_key, expires_in: anything).and_call_original

        adapter.current_weather(location: "London")
      end

      it "handles city name" do
        forecast = adapter.current_weather(location: "London")
        expect(forecast).to be_a(Weather::Forecast)
      end

      it "handles zipcode" do
        forecast = adapter.current_weather(location: "90210")
        expect(forecast).to be_a(Weather::Forecast)
      end

      it "handles coordinates" do
        forecast = adapter.current_weather(location: "51.5074,-0.1278")
        expect(forecast).to be_a(Weather::Forecast)
      end
    end

    context "with API errors" do
      it "raises LocationNotFoundError for 404" do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/weather})
          .to_return(status: 404, body: '{"message":"city not found"}', headers: { "Content-Type" => "application/json" })

        expect {
          adapter.current_weather(location: "InvalidCity")
        }.to raise_error(Weather::BaseAdapter::LocationNotFoundError)
      end

      it "raises RateLimitError for 429" do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/weather})
          .to_return(status: 429, body: "{}", headers: { "Content-Type" => "application/json" })

        expect {
          adapter.current_weather(location: "London")
        }.to raise_error(Weather::BaseAdapter::RateLimitError)
      end

      it "raises ApiError for 401" do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/weather})
          .to_return(status: 401, body: "{}", headers: { "Content-Type" => "application/json" })

        expect {
          adapter.current_weather(location: "London")
        }.to raise_error(Weather::BaseAdapter::ApiError, /configuration error/)
      end

      it "raises ApiError for 500" do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/weather})
          .to_return(status: 500, body: "{}", headers: { "Content-Type" => "application/json" })

        expect {
          adapter.current_weather(location: "London")
        }.to raise_error(Weather::BaseAdapter::ApiError)
      end

      it "raises ApiError on connection timeout" do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/weather})
          .to_raise(Net::OpenTimeout)

        expect {
          adapter.current_weather(location: "London")
        }.to raise_error(Weather::BaseAdapter::ApiError, /timed out/)
      end

      it "raises ApiError on read timeout" do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/weather})
          .to_raise(Net::ReadTimeout)

        expect {
          adapter.current_weather(location: "London")
        }.to raise_error(Weather::BaseAdapter::ApiError, /did not respond/)
      end

      it "raises ApiError on connection refused" do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/weather})
          .to_raise(Errno::ECONNREFUSED)

        expect {
          adapter.current_weather(location: "London")
        }.to raise_error(Weather::BaseAdapter::ApiError, /Connection failed/)
      end
    end
  end

  describe "#forecast" do
    let(:api_response) do
      {
        "city" => {
          "name" => "London"
        },
        "list" => [
          {
            "dt" => Time.current.to_i,
            "main" => { "temp" => 15.5, "humidity" => 72 },
            "weather" => [ { "main" => "Clouds", "description" => "partly cloudy" } ],
            "wind" => { "speed" => 12.5, "deg" => 315 },
            "pop" => 0.2
          },
          {
            "dt" => (Time.current + 3.hours).to_i,
            "main" => { "temp" => 16.0, "humidity" => 70 },
            "weather" => [ { "main" => "Clear", "description" => "clear sky" } ],
            "wind" => { "speed" => 10.0, "deg" => 300 },
            "pop" => 0.1
          }
        ]
      }
    end

    context "with successful API call" do
      before do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/forecast})
          .to_return(status: 200, body: api_response.to_json, headers: { "Content-Type" => "application/json" })
      end

      it "returns array of forecasts" do
        forecasts = adapter.forecast(location: "London", days: 7)

        expect(forecasts).to be_an(Array)
        expect(forecasts.first).to be_a(Weather::Forecast)
        expect(forecasts.first.location).to eq("London")
      end

      it "uses default days value" do
        forecasts = adapter.forecast(location: "London")

        expect(forecasts).to be_an(Array)
      end

      it "caches the result" do
        # cache key now includes days to prevent different-day collisions (issue #54)
        cache_key = adapter.send(:cache_key, location: "London", type: :forecast, days: 5)

        expect(Rails.cache).to receive(:fetch).with(cache_key, expires_in: anything).and_call_original

        adapter.forecast(location: "London", days: 5)
      end
    end

    context "with API errors" do
      it "raises LocationNotFoundError for 404" do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/forecast})
          .to_return(status: 404, body: '{"message":"city not found"}', headers: { "Content-Type" => "application/json" })

        expect {
          adapter.forecast(location: "InvalidCity")
        }.to raise_error(Weather::BaseAdapter::LocationNotFoundError)
      end

      it "raises RateLimitError for 429" do
        stub_request(:get, %r{api.openweathermap.org/data/2.5/forecast})
          .to_return(status: 429, body: "{}", headers: { "Content-Type" => "application/json" })

        expect {
          adapter.forecast(location: "London")
        }.to raise_error(Weather::BaseAdapter::RateLimitError)
      end
    end
  end

  describe "#service_name" do
    it "returns service name" do
      expect(adapter.service_name).to eq("OpenWeatherMap")
    end
  end

  describe "HTTP timeout configuration" do
    it "uses default open timeout of 5 seconds" do
      expect(adapter.send(:http_open_timeout)).to eq(5)
    end

    it "uses default read timeout of 10 seconds" do
      expect(adapter.send(:http_read_timeout)).to eq(10)
    end

    it "reads open timeout from HTTP_OPEN_TIMEOUT env var" do
      allow(ENV).to receive(:fetch).with("HTTP_OPEN_TIMEOUT", 5).and_return("3")
      expect(adapter.send(:http_open_timeout)).to eq(3)
    end

    it "reads read timeout from HTTP_READ_TIMEOUT env var" do
      allow(ENV).to receive(:fetch).with("HTTP_READ_TIMEOUT", 10).and_return("15")
      expect(adapter.send(:http_read_timeout)).to eq(15)
    end
  end

  describe "helper methods" do
    describe "#degrees_to_direction" do
      it "converts degrees to cardinal direction" do
        expect(adapter.send(:degrees_to_direction, 0)).to eq("N")
        expect(adapter.send(:degrees_to_direction, 90)).to eq("E")
        expect(adapter.send(:degrees_to_direction, 180)).to eq("S")
        expect(adapter.send(:degrees_to_direction, 270)).to eq("W")
        expect(adapter.send(:degrees_to_direction, 315)).to eq("NW")
      end

      it "handles nil degrees" do
        expect(adapter.send(:degrees_to_direction, nil)).to be_nil
      end
    end

    describe "#calculate_precipitation_chance" do
      it "estimates precipitation based on weather ID" do
        # Thunderstorm
        expect(adapter.send(:calculate_precipitation_chance, { "weather" => [ { "id" => 200 } ] })).to eq(80.0)
        # Rain
        expect(adapter.send(:calculate_precipitation_chance, { "weather" => [ { "id" => 500 } ] })).to eq(70.0)
        # Clear
        expect(adapter.send(:calculate_precipitation_chance, { "weather" => [ { "id" => 800 } ] })).to eq(0.0)
      end
    end
  end
end
