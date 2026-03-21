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
      def current
        debug_me { [ :@location ] }

        start_time = Time.current
        cache_key = weather_service.current_cache_key(location: @location)
        cached = Rails.cache.exist?(cache_key)

        forecast = weather_service.current_weather(location: @location)
        duration_ms = ((Time.current - start_time) * 1000).round(2)

        render json: {
          data: forecast.to_h,
          performance: {
            cached: cached,
            duration_ms: duration_ms
          }
        }
      end

      # GET /api/v1/forecast?location=<location>&days=<days>
      # Returns multi-day weather forecast for the specified location
      #
      # Parameters:
      #   location (required) - City name, zip code, or coordinates (lat,lon)
      #   days (optional) - Number of days to forecast (default: 7, max: 14)
      def forecast
        debug_me { [ :@location, :@days ] }

        start_time = Time.current
        cache_key = weather_service.forecast_cache_key(location: @location, days: @days)
        cached = Rails.cache.exist?(cache_key)

        forecasts = weather_service.forecast(location: @location, days: @days)
        duration_ms = ((Time.current - start_time) * 1000).round(2)

        render json: {
          data: forecasts.map(&:to_h),
          performance: {
            cached: cached,
            duration_ms: duration_ms
          }
        }
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
      def weather_service
        @weather_service ||= Weather::OpenWeatherMapAdapter.new
      end
    end
  end
end
