# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Weather", type: :request do
  let(:mock_adapter) { instance_double(Weather::OpenWeatherMapAdapter) }
  let(:forecast) do
    Weather::Forecast.new(
      location: "London",
      timestamp: Time.current,
      temperature: { celsius: 15.5 },
      conditions: "Partly Cloudy",
      description: "Partly cloudy with a chance of rain",
      humidity: 72.0,
      wind_speed: 12.5,
      wind_direction: "NW",
      precipitation_chance: 20.0
    )
  end

  before do
    allow(Weather::OpenWeatherMapAdapter).to receive(:new).and_return(mock_adapter)
  end

  describe "GET /api/v1/current" do
    context "with valid location" do
      it "returns current weather data" do
        allow(mock_adapter).to receive(:current_weather).with(location: "London").and_return(forecast)

        get "/api/v1/current", params: { location: "London" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["location"]).to eq("London")
        expect(json["conditions"]).to eq("Partly Cloudy")
        expect(json["temperature"]["celsius"]).to eq(15.5)
      end

      it "handles zipcode format" do
        allow(mock_adapter).to receive(:current_weather).with(location: "90210").and_return(forecast)

        get "/api/v1/current", params: { location: "90210" }

        expect(response).to have_http_status(:success)
      end

      it "handles coordinate format" do
        allow(mock_adapter).to receive(:current_weather).with(location: "51.5074,-0.1278").and_return(forecast)

        get "/api/v1/current", params: { location: "51.5074,-0.1278" }

        expect(response).to have_http_status(:success)
      end
    end

    context "with missing location" do
      it "returns bad request" do
        get "/api/v1/current"

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Location parameter is required")
      end
    end

    context "with invalid location" do
      it "returns not found" do
        allow(mock_adapter).to receive(:current_weather)
          .and_raise(Weather::BaseAdapter::LocationNotFoundError, "Invalid location")

        get "/api/v1/current", params: { location: "InvalidCity123" }

        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Location not found")
      end
    end

    context "with rate limit exceeded" do
      it "returns too many requests" do
        allow(mock_adapter).to receive(:current_weather)
          .and_raise(Weather::BaseAdapter::RateLimitError, "Rate limit exceeded")

        get "/api/v1/current", params: { location: "London" }

        expect(response).to have_http_status(:too_many_requests)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("rate limit")
      end
    end

    context "with API error" do
      it "returns service unavailable" do
        allow(mock_adapter).to receive(:current_weather)
          .and_raise(Weather::BaseAdapter::ApiError, "API error")

        get "/api/v1/current", params: { location: "London" }

        expect(response).to have_http_status(:service_unavailable)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("unavailable")
      end
    end

    context "with unexpected error" do
      it "returns internal server error" do
        allow(mock_adapter).to receive(:current_weather)
          .and_raise(StandardError, "Unexpected error")

        get "/api/v1/current", params: { location: "London" }

        expect(response).to have_http_status(:internal_server_error)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("unexpected error")
      end
    end
  end

  describe "GET /api/v1/forecast" do
    let(:forecasts) { [ forecast, forecast ] }

    context "with valid location" do
      it "returns forecast data" do
        allow(mock_adapter).to receive(:forecast).with(location: "London", days: 7).and_return(forecasts)

        get "/api/v1/forecast", params: { location: "London" }

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json).to be_an(Array)
        expect(json.length).to eq(2)
        expect(json.first["location"]).to eq("London")
      end

      it "accepts days parameter" do
        allow(mock_adapter).to receive(:forecast).with(location: "London", days: 5).and_return(forecasts)

        get "/api/v1/forecast", params: { location: "London", days: 5 }

        expect(response).to have_http_status(:success)
      end

      it "uses default days value" do
        allow(mock_adapter).to receive(:forecast).with(location: "London", days: 7).and_return(forecasts)

        get "/api/v1/forecast", params: { location: "London" }

        expect(response).to have_http_status(:success)
      end
    end

    context "with invalid days parameter" do
      it "returns bad request for days < 1" do
        get "/api/v1/forecast", params: { location: "London", days: 0 }

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Days parameter must be between 1 and 14")
      end

      it "returns bad request for days > 14" do
        get "/api/v1/forecast", params: { location: "London", days: 15 }

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Days parameter must be between 1 and 14")
      end
    end

    context "with missing location" do
      it "returns bad request" do
        get "/api/v1/forecast"

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("Location parameter is required")
      end
    end

    context "with error handling" do
      it "handles location not found" do
        allow(mock_adapter).to receive(:forecast)
          .and_raise(Weather::BaseAdapter::LocationNotFoundError, "Invalid location")

        get "/api/v1/forecast", params: { location: "InvalidCity123" }

        expect(response).to have_http_status(:not_found)
      end

      it "handles rate limit error" do
        allow(mock_adapter).to receive(:forecast)
          .and_raise(Weather::BaseAdapter::RateLimitError, "Rate limit exceeded")

        get "/api/v1/forecast", params: { location: "London" }

        expect(response).to have_http_status(:too_many_requests)
      end

      it "handles API error" do
        allow(mock_adapter).to receive(:forecast)
          .and_raise(Weather::BaseAdapter::ApiError, "API error")

        get "/api/v1/forecast", params: { location: "London" }

        expect(response).to have_http_status(:service_unavailable)
      end
    end
  end
end
