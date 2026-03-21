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
        @weather_duration_ms = ((Time.current - start_time) * 1000).round(2)
        @cached = weather_service.last_cache_hit?

        render json: {
          data: forecast.to_h,
          performance: {
            cached: @cached,
            duration_ms: @weather_duration_ms
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
        @weather_duration_ms = ((Time.current - start_time) * 1000).round(2)
        @cached = weather_service.last_cache_hit?

        render json: {
          data: forecasts.map(&:to_h),
          performance: {
            cached: @cached,
            duration_ms: @weather_duration_ms
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

      # Inject weather-specific fields into the process_action.action_controller
      # instrumentation payload so they appear in the single structured log entry
      # emitted by Console::Adapter::Rails::ActionController per request.
      def append_info_to_payload(payload)
        super
        payload[:location]           = @location          if @location
        payload[:cached]             = @cached             unless @cached.nil?
        payload[:weather_duration_ms] = @weather_duration_ms if @weather_duration_ms
        payload[:days]               = @days               if @days
      end
    end
  end
end
