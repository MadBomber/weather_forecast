# frozen_string_literal: true

module Weather
  # Value object representing a weather forecast
  class Forecast
    attr_reader :location, :timestamp, :temperature, :conditions,
                :humidity, :wind_speed, :wind_direction,
                :precipitation_chance, :description

    def initialize(
      location:,
      timestamp:,
      temperature:,
      conditions:,
      humidity: nil,
      wind_speed: nil,
      wind_direction: nil,
      precipitation_chance: nil,
      description: nil
    )
      @location = location
      @timestamp = parse_timestamp(timestamp)
      @temperature = ensure_temperature(temperature)
      @conditions = conditions
      @humidity = humidity&.to_f
      @wind_speed = wind_speed&.to_f
      @wind_direction = wind_direction
      @precipitation_chance = precipitation_chance&.to_f
      @description = description
    end

    def to_h
      {
        location: location,
        timestamp: timestamp.iso8601,
        temperature: temperature.to_h,
        conditions: conditions,
        humidity: humidity&.round(1),
        wind_speed: wind_speed&.round(1),
        wind_direction: wind_direction,
        precipitation_chance: precipitation_chance&.round(1),
        description: description
      }.compact
    end

    def to_json(*args)
      to_h.to_json(*args)
    end

    private

    def parse_timestamp(timestamp)
      case timestamp
      when Time, DateTime
        timestamp.to_time
      when String
        Time.parse(timestamp)
      else
        timestamp
      end
    end

    def ensure_temperature(temp)
      return temp if temp.is_a?(Temperature)

      if temp.is_a?(Hash)
        Temperature.new(**temp.symbolize_keys)
      elsif temp.is_a?(Numeric)
        Temperature.new(celsius: temp)
      else
        raise ArgumentError, "Invalid temperature format: #{temp.class}"
      end
    end
  end
end
