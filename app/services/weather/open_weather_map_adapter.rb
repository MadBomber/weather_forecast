# frozen_string_literal: true

module Weather
  # OpenWeatherMap API adapter
  # Integrates with OpenWeatherMap API for weather data
  # API Documentation: https://openweathermap.org/api
  class OpenWeatherMapAdapter < BaseAdapter
    include BreakerMachines::DSL

    # Circuit breaker protecting outbound HTTP calls to OpenWeatherMap.
    #
    # Opens after 3 network-level failures within 30 seconds, then waits
    # 30 seconds before allowing a single probe request through (half-open).
    # Only connection/timeout errors count as failures; valid API error
    # responses (404, 429, etc.) do not trip the circuit.
    #
    # When open, the fallback raises ApiError so the existing rescue_from
    # in ApplicationController returns HTTP 503 to the caller.
    circuit :openweathermap do
      threshold failures: 3, within: 30.seconds
      reset_after 30.seconds
      handle Net::OpenTimeout, Net::ReadTimeout,
             Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError
      # The fallback is called in two contexts:
      #   1. Circuit is CLOSED but a failure just occurred (error = original network exception)
      #   2. Circuit is OPEN and rejecting the call  (error = BreakerMachines::CircuitOpenError)
      # Re-raise the original network exception in case (1) so the rescue clauses in
      # perform_get can map it to a descriptive ApiError message.  Only raise the
      # "circuit open" message in case (2) when the circuit is actually blocking calls.
      fallback do |error|
        raise ApiError, "Weather service temporarily unavailable (circuit open)" if error.is_a?(BreakerMachines::CircuitOpenError)

        raise error
      end
    end
    BASE_URL = "https://api.openweathermap.org/data/2.5"
    # OWM free tier provides at most 5 days of 3-hourly data (40 data points).
    MAX_FORECAST_DAYS = 5

    # Fetch current weather for a location
    # @param location [String] Location identifier (city name, zip code, or coordinates)
    # @return [Weather::Forecast] Current weather forecast
    def current_weather(location:)
      cache_key_value = cache_key(location: location, type: :current)

      cache_fetch(cache_key_value, expires_in: current_ttl) do
        parse_current_weather(fetch_current_weather(location))
      end
    end

    # Fetch multi-day forecast for a location
    # @param location [String] Location identifier
    # @param days [Integer] Number of days to forecast (default: 7)
    # @return [Array<Weather::Forecast>] Array of weather forecasts
    def forecast(location:, days: 7)
      cache_key_value = cache_key(location: location, type: :forecast, days: days)

      cache_fetch(cache_key_value, expires_in: forecast_ttl) do
        parse_forecast(fetch_forecast(location, days), days)
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
      make_request(url, params)
    end

    # Fetch forecast from OpenWeatherMap API
    # OWM free tier caps at 5 days / 40 data points regardless of cnt sent.
    def fetch_forecast(location, days)
      url = "#{BASE_URL}/forecast"
      params = build_params(location)
      effective_days = [ days, MAX_FORECAST_DAYS ].min
      params[:cnt] = effective_days * 8 # 8 three-hourly data points per day
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

    # Make HTTP request to OpenWeatherMap API.
    # Under Falcon's fiber scheduler (Ruby 3.x + io-event), Net::HTTP socket
    # operations yield the fiber automatically — no additional async client needed.
    # See ADR-0013 for the full rationale.
    def make_request(url, params)
      uri = URI(url)
      uri.query = URI.encode_www_form(params)
      response = perform_get(uri)
      handle_response(response)
    end

    # Execute the GET request, wrapped in the :openweathermap circuit breaker.
    # Network-level exceptions (timeout, refused, reset) are counted as failures.
    # When the circuit opens the fallback raises ApiError immediately.
    def perform_get(uri)
      circuit(:openweathermap).wrap do
        Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https",
                        open_timeout: http_open_timeout,
                        read_timeout: http_read_timeout) do |http|
          http.get("#{uri.path}?#{uri.query}")
        end
      end
    rescue Net::OpenTimeout
      raise ApiError, "Connection to weather service timed out"
    rescue Net::ReadTimeout
      raise ApiError, "Weather service did not respond in time"
    rescue Errno::ECONNREFUSED, Errno::ECONNRESET, SocketError => e
      raise ApiError, "Connection failed: #{e.message}"
    end

    # Handle API response and errors.
    # Logs upstream details for internal diagnostics but exposes only safe messages to callers.
    def handle_response(response)
      case response.code.to_i
      when 200
        JSON.parse(response.body)
      when 404
        upstream = safe_parse_json(response.body)["message"]
        Rails.logger.info("OWM 404: #{upstream}")
        raise LocationNotFoundError, "Location not found"
      when 429
        raise RateLimitError, "API rate limit exceeded"
      when 401
        Rails.logger.error("OWM rejected API key (401)")
        raise ApiError, "Weather service configuration error"
      else
        Rails.logger.error("OWM unexpected status #{response.code}: #{response.body.to_s.truncate(200)}")
        raise ApiError, "Weather service temporarily unavailable"
      end
    rescue JSON::ParserError
      raise ApiError, "Invalid JSON response from API"
    end

    def http_open_timeout
      Integer(ENV.fetch("HTTP_OPEN_TIMEOUT", 5))
    end

    def http_read_timeout
      Integer(ENV.fetch("HTTP_READ_TIMEOUT", 10))
    end

    # Parse current weather response into Forecast object
    def parse_current_weather(response)
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
      when 200..299 then 80.0  # Thunderstorm
      when 300..399 then 60.0  # Drizzle
      when 500..599 then 70.0  # Rain
      when 600..699 then 70.0  # Snow
      when 700..799 then 30.0  # Atmosphere (fog, mist, etc.)
      when 800 then 0.0        # Clear
      when 801..804 then 20.0  # Clouds
      end
    end

    def safe_parse_json(body)
      JSON.parse(body.to_s)
    rescue JSON::ParserError
      {}
    end
  end
end
