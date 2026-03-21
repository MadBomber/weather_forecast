# frozen_string_literal: true

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
        start_time = Time.current
        forecast = weather_service.current_weather(location: @location)
        duration_ms = ((Time.current - start_time) * 1000).round(2)
        cached = weather_service.last_cache_hit?

        log_weather_event("weather.current",
                          location: @location,
                          cached: cached,
                          duration_ms: duration_ms,
                          status: 200)

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
        start_time = Time.current
        forecasts = weather_service.forecast(location: @location, days: @days)
        duration_ms = ((Time.current - start_time) * 1000).round(2)
        cached = weather_service.last_cache_hit?

        log_weather_event("weather.forecast",
                          location: @location,
                          days: @days,
                          cached: cached,
                          duration_ms: duration_ms,
                          status: 200)

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

      # Get the configured weather service adapter (resolved via AdapterFactory)
      def weather_service
        @weather_service ||= Weather::AdapterFactory.build
      end

      # Emit a structured log line for a weather API event.
      #
      # With Lumberjack as the logger (production) the attributes become
      # top-level JSON fields so aggregators can filter on them individually.
      # With the default Rails text logger (development / test) the attributes
      # are inlined as key=value pairs in the message string.
      def log_weather_event(event, **attrs)
        if Rails.logger.respond_to?(:add_entry)
          Rails.logger.info(event, attrs)
        else
          parts = attrs.map { |k, v| "#{k}=#{v.inspect}" }.join(" ")
          Rails.logger.info("[#{event}] #{parts}")
        end
      end
    end
  end
end
