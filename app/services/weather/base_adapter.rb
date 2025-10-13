# frozen_string_literal: true

require "debug_me"
include DebugMe

module Weather
  # Base adapter class for weather API integrations
  # Defines the interface that all weather adapters must implement
  class BaseAdapter
    class LocationNotFoundError < StandardError; end
    class ApiError < StandardError; end
    class RateLimitError < StandardError; end

    def initialize(api_key: nil)
      @api_key = api_key || default_api_key
      debug_me { [ :@api_key ] } if @api_key
    end

    # Fetch current weather for a location
    # @param location [String] Location identifier (city name, zip code, coordinates, etc.)
    # @return [Weather::Forecast] Current weather forecast
    # @raise [LocationNotFoundError] if location cannot be found
    # @raise [ApiError] if API request fails
    def current_weather(location:)
      raise NotImplementedError, "Subclasses must implement #current_weather"
    end

    # Fetch multi-day forecast for a location
    # @param location [String] Location identifier
    # @param days [Integer] Number of days to forecast (default: 7)
    # @return [Array<Weather::Forecast>] Array of weather forecasts
    # @raise [LocationNotFoundError] if location cannot be found
    # @raise [ApiError] if API request fails
    def forecast(location:, days: 7)
      raise NotImplementedError, "Subclasses must implement #forecast"
    end

    # Check if the adapter is properly configured
    # @return [Boolean] true if adapter has necessary configuration
    def configured?
      @api_key.present?
    end

    # Get the name of the weather service
    # @return [String] Service name
    def service_name
      self.class.name.demodulize.gsub("Adapter", "")
    end

    protected

    attr_reader :api_key

    # Get default API key from environment
    # Subclasses should override to specify their env var
    def default_api_key
      nil
    end

    # Build cache key for weather data
    # @param location [String] Location identifier
    # @param type [Symbol] Type of data (:current or :forecast)
    # @return [String] Cache key
    def cache_key(location:, type: :current)
      normalized_location = location.to_s.downcase.strip.gsub(/\s+/, "_")
      hour_bucket = Time.current.to_i / 3600 # Bucket by hour
      "weather:#{service_name}:#{type}:#{normalized_location}:#{hour_bucket}"
    end

    # Default cache TTL for current weather (30 minutes)
    def current_ttl
      ENV.fetch("REDIS_TTL_CURRENT", 30.minutes).to_i
    end

    # Default cache TTL for forecast (30 minutes)
    def forecast_ttl
      ENV.fetch("REDIS_TTL_FORECAST", 30.minutes).to_i
    end
  end
end
