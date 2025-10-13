# frozen_string_literal: true

require "debug_me"
include DebugMe

module Weather
  # OpenWeatherMap API adapter
  # Integrates with OpenWeatherMap API for weather data
  # API Documentation: https://openweathermap.org/api
  class OpenWeatherMapAdapter < BaseAdapter
    BASE_URL = "https://api.openweathermap.org/data/2.5"

    # Fetch current weather for a location
    # @param location [String] Location identifier (city name, zip code, or coordinates)
    # @return [Weather::Forecast] Current weather forecast
    def current_weather(location:)
      debug_me { [ :location ] }

      cache_key_value = cache_key(location: location, type: :current)

      Rails.cache.fetch(cache_key_value, expires_in: current_ttl) do
        response = fetch_current_weather(location)
        parse_current_weather(response)
      end
    end

    # Fetch multi-day forecast for a location
    # @param location [String] Location identifier
    # @param days [Integer] Number of days to forecast (default: 7)
    # @return [Array<Weather::Forecast>] Array of weather forecasts
    def forecast(location:, days: 7)
      debug_me { [ :location, :days ] }

      cache_key_value = cache_key(location: location, type: :forecast)

      Rails.cache.fetch(cache_key_value, expires_in: forecast_ttl) do
        response = fetch_forecast(location, days)
        parse_forecast(response, days)
      end
    end

    protected

    # Get OpenWeatherMap API key from environment
    def default_api_key
      ENV.fetch("OPENWEATHERMAP_API_KEY", nil)
    end

    private

    # Fetch current weather from OpenWeatherMap API
    def fetch_current_weather(location)
      url = "#{BASE_URL}/weather"
      params = build_params(location)

      debug_me { [ :url, :params ] }

      make_request(url, params)
    end

    # Fetch forecast from OpenWeatherMap API
    def fetch_forecast(location, days)
      # OpenWeatherMap free tier provides 5-day/3-hour forecast
      # We'll use the forecast endpoint and filter by days
      url = "#{BASE_URL}/forecast"
      params = build_params(location)
      params[:cnt] = days * 8 # 8 data points per day (every 3 hours)

      debug_me { [ :url, :params ] }

      make_request(url, params)
    end

    # Build common query parameters
    def build_params(location)
      params = {
        appid: api_key,
        units: "metric" # Use metric units (Celsius)
      }

      # Determine if location is coordinates (lat,lon) or name
      if location.match?(/^-?\d+\.?\d*,-?\d+\.?\d*$/)
        lat, lon = location.split(",").map(&:to_f)
        params[:lat] = lat
        params[:lon] = lon
      elsif location.match?(/^\d{5}$/) # US zip code
        params[:zip] = "#{location},US"
      else
        params[:q] = location
      end

      params
    end

    # Make HTTP request to OpenWeatherMap API
    def make_request(url, params)
      uri = URI(url)
      uri.query = URI.encode_www_form(params)

      debug_me { [ :uri ] }

      response = Net::HTTP.get_response(uri)

      debug_me { [ :response_code ] }

      handle_response(response)
    end

    # Handle API response and errors
    def handle_response(response)
      case response.code.to_i
      when 200
        JSON.parse(response.body)
      when 404
        error_data = JSON.parse(response.body) rescue {}
        raise LocationNotFoundError, error_data["message"] || "Location not found"
      when 429
        raise RateLimitError, "API rate limit exceeded"
      when 401
        raise ApiError, "Invalid API key"
      else
        error_data = JSON.parse(response.body) rescue {}
        raise ApiError, error_data["message"] || "API request failed with status #{response.code}"
      end
    rescue JSON::ParserError => e
      debug_me { [ :e ] }
      raise ApiError, "Invalid JSON response from API"
    end

    # Parse current weather response into Forecast object
    def parse_current_weather(response)
      debug_me { [ :response ] }

      Weather::Forecast.new(
        location: response["name"] || "Unknown",
        timestamp: Time.at(response["dt"]),
        temperature: {
          celsius: response.dig("main", "temp")
        },
        conditions: response.dig("weather", 0, "main") || "Unknown",
        description: response.dig("weather", 0, "description"),
        humidity: response.dig("main", "humidity"),
        wind_speed: response.dig("wind", "speed"),
        wind_direction: degrees_to_direction(response.dig("wind", "deg")),
        precipitation_chance: calculate_precipitation_chance(response)
      )
    end

    # Parse forecast response into array of Forecast objects
    def parse_forecast(response, days)
      debug_me { [ :response, :days ] }

      location_name = response.dig("city", "name") || "Unknown"

      # Filter forecasts to requested number of days
      end_time = Time.current + days.days

      response["list"]
        .select { |item| Time.at(item["dt"]) <= end_time }
        .map do |item|
          Weather::Forecast.new(
            location: location_name,
            timestamp: Time.at(item["dt"]),
            temperature: {
              celsius: item.dig("main", "temp")
            },
            conditions: item.dig("weather", 0, "main") || "Unknown",
            description: item.dig("weather", 0, "description"),
            humidity: item.dig("main", "humidity"),
            wind_speed: item.dig("wind", "speed"),
            wind_direction: degrees_to_direction(item.dig("wind", "deg")),
            precipitation_chance: item.dig("pop") ? item["pop"] * 100 : nil
          )
        end
    end

    # Convert wind direction from degrees to cardinal direction
    def degrees_to_direction(degrees)
      return nil if degrees.nil?

      directions = %w[N NNE NE ENE E ESE SE SSE S SSW SW WSW W WNW NW NNW]
      index = ((degrees + 11.25) / 22.5).to_i % 16
      directions[index]
    end

    # Calculate precipitation chance from current weather data
    # Current weather endpoint doesn't provide PoP, so we estimate based on conditions
    def calculate_precipitation_chance(response)
      weather_id = response.dig("weather", 0, "id")
      return nil unless weather_id

      case weather_id
      when 200..299 # Thunderstorm
        80.0
      when 300..399 # Drizzle
        60.0
      when 500..599 # Rain
        70.0
      when 600..699 # Snow
        70.0
      when 700..799 # Atmosphere (fog, mist, etc.)
        30.0
      when 800 # Clear
        0.0
      when 801..804 # Clouds
        20.0
      else
        nil
      end
    end
  end
end
