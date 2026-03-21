# frozen_string_literal: true

module Weather
  # Resolves the configured weather adapter class.
  # Set WEATHER_ADAPTER env var to switch providers without code changes.
  # Defaults to OpenWeatherMapAdapter.
  #
  # Example:
  #   WEATHER_ADAPTER=Weather::OpenWeatherMapAdapter  (default)
  #   WEATHER_ADAPTER=Weather::NwsAdapter             (future provider)
  class AdapterFactory
    DEFAULT_ADAPTER = "Weather::OpenWeatherMapAdapter"

    def self.build
      adapter_class = ENV.fetch("WEATHER_ADAPTER", DEFAULT_ADAPTER)
      adapter_class.constantize.new
    rescue NameError => e
      raise ArgumentError, "Unknown weather adapter '#{adapter_class}': #{e.message}"
    end
  end
end
