# frozen_string_literal: true

require "debug_me"
include DebugMe

module Api
  module V1
    # Weather API controller
    # Provides endpoints for current weather and forecast data
    class WeatherController < ApplicationController
      before_action :validate_location_param, only: [ :current, :forecast ]
      before_action :validate_days_param, only: [ :forecast ]

      # GET /api/v1/current?location=<location>
      # Returns current weather for the specified location
      #
      # Parameters:
      #   location (required) - City name, zip code, or coordinates (lat,lon)
      #
      # Example:
      #   GET /api/v1/current?location=London
      #   GET /api/v1/current?location=90210
      #   GET /api/v1/current?location=51.5074,-0.1278
      #
      # Response:
      #   {
      #     "location": "London",
      #     "timestamp": "2025-10-12T10:30:00Z",
      #     "temperature": {
      #       "celsius": 15.5,
      #       "fahrenheit": 59.9,
      #       "kelvin": 288.7
      #     },
      #     "conditions": "Partly Cloudy",
      #     "humidity": 72.0,
      #     "wind_speed": 12.5,
      #     "wind_direction": "NW",
      #     "precipitation_chance": 20.0,
      #     "description": "Partly cloudy with a chance of rain"
      #   }
      def current
        debug_me { [ :@location ] }

        forecast = weather_service.current_weather(location: @location)
        render json: forecast.to_h
      rescue Weather::BaseAdapter::LocationNotFoundError => e
        debug_me "LocationNotFoundError: #{e.message}"
        render json: { error: "Location not found: #{@location}" }, status: :not_found
      rescue Weather::BaseAdapter::RateLimitError => e
        debug_me "RateLimitError: #{e.message}"
        render json: { error: "API rate limit exceeded. Please try again later." }, status: :too_many_requests
      rescue Weather::BaseAdapter::ApiError => e
        debug_me "ApiError: #{e.message}"
        render json: { error: "Weather service unavailable. Please try again later." }, status: :service_unavailable
      rescue StandardError => e
        debug_me "StandardError: #{e.message}"
        debug_me { [ e.backtrace ] }
        render json: { error: "An unexpected error occurred." }, status: :internal_server_error
      end

      # GET /api/v1/forecast?location=<location>&days=<days>
      # Returns multi-day weather forecast for the specified location
      #
      # Parameters:
      #   location (required) - City name, zip code, or coordinates (lat,lon)
      #   days (optional) - Number of days to forecast (default: 7, max: 14)
      #
      # Example:
      #   GET /api/v1/forecast?location=London&days=5
      #
      # Response:
      #   [
      #     {
      #       "location": "London",
      #       "timestamp": "2025-10-12T12:00:00Z",
      #       "temperature": {...},
      #       "conditions": "Sunny",
      #       ...
      #     },
      #     ...
      #   ]
      def forecast
        debug_me { [ :@location, :@days ] }

        forecasts = weather_service.forecast(location: @location, days: @days)
        render json: forecasts.map(&:to_h)
      rescue Weather::BaseAdapter::LocationNotFoundError => e
        debug_me "LocationNotFoundError: #{e.message}"
        render json: { error: "Location not found: #{@location}" }, status: :not_found
      rescue Weather::BaseAdapter::RateLimitError => e
        debug_me "RateLimitError: #{e.message}"
        render json: { error: "API rate limit exceeded. Please try again later." }, status: :too_many_requests
      rescue Weather::BaseAdapter::ApiError => e
        debug_me "ApiError: #{e.message}"
        render json: { error: "Weather service unavailable. Please try again later." }, status: :service_unavailable
      rescue StandardError => e
        debug_me "StandardError: #{e.message}"
        debug_me { [ e.backtrace ] }
        render json: { error: "An unexpected error occurred." }, status: :internal_server_error
      end

      private

      # Validate that location parameter is present
      def validate_location_param
        @location = params[:location]&.strip

        if @location.blank?
          render json: { error: "Location parameter is required" }, status: :bad_request
        end
      end

      # Validate and set days parameter for forecast
      def validate_days_param
        @days = params[:days]&.to_i || 7

        if @days < 1 || @days > 14
          render json: { error: "Days parameter must be between 1 and 14" }, status: :bad_request
        end
      end

      # Get the configured weather service adapter
      # This can be overridden to support multiple weather services
      # or to inject a mock service for testing
      def weather_service
        @weather_service ||= Weather::OpenWeatherMapAdapter.new
      end
    end
  end
end
