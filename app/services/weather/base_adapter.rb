# frozen_string_literal: true

module Weather
  # Base adapter class for weather API integrations
  # Defines the interface that all weather adapters must implement
  class BaseAdapter
    class LocationNotFoundError < StandardError; end
    class ApiError < StandardError; end
    class RateLimitError < StandardError; end

    def initialize(api_key: nil)
      @api_key = api_key || default_api_key
      unless configured?
        Rails.logger.warn("#{self.class.name}: no API key configured — requests will fail with 401")
      end
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

    # Whether the most recent fetch was served from cache.
    # Set atomically inside #cache_fetch — no separate exist? check needed.
    def last_cache_hit?
      @last_cache_hit
    end

    # Get the name of the weather service
    # @return [String] Service name
    def service_name
      self.class.name.demodulize.gsub("Adapter", "")
    end

    # Get cache key for forecast data
    # @param location [String] Location identifier
    # @param days [Integer] Number of days — included in the key so different day counts don't collide
    # @return [String] Cache key
    def forecast_cache_key(location:, days: 7)
      cache_key(location: location, type: :forecast, days: days)
    end

    # Get cache key for current weather data
    # @param location [String] Location identifier
    # @return [String] Cache key
    def current_cache_key(location:)
      cache_key(location: location, type: :current)
    end

    protected

    attr_reader :api_key

    # Get default API key from environment
    # Subclasses should override to specify their env var
    def default_api_key
      nil
    end

    # Atomic cache fetch that also tracks whether the result was a cache hit.
    # The block is only executed on a cache miss, so @last_cache_hit is set correctly
    # without a separate Rails.cache.exist? call (which would introduce a TOCTOU race).
    def cache_fetch(key, expires_in:, &block)
      hit = true
      result = Rails.cache.fetch(key, expires_in: expires_in) do
        hit = false
        block.call
      end
      @last_cache_hit = hit
      result
    end

    # Build cache key for weather data
    # @param location [String] Location identifier
    # @param type [Symbol] Type of data (:current or :forecast)
    # @param days [Integer, nil] Number of forecast days; included only for :forecast type
    # @return [String] Cache key
    def cache_key(location:, type: :current, days: nil)
      normalized_location = location.to_s.downcase.strip.gsub(/\s+/, "_")
      hour_bucket = Time.current.to_i / 3600 # Bucket by hour
      parts = [ "weather", service_name, type, normalized_location, hour_bucket ]
      parts << days if days
      parts.join(":")
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
