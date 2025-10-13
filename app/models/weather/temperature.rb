# frozen_string_literal: true

module Weather
  # Value object representing temperature with conversion capabilities
  # Supports both Celsius and Fahrenheit
  class Temperature
    include Comparable

    attr_reader :celsius

    def initialize(celsius: nil, fahrenheit: nil, kelvin: nil)
      if celsius
        @celsius = celsius.to_f
      elsif fahrenheit
        @celsius = fahrenheit_to_celsius(fahrenheit.to_f)
      elsif kelvin
        @celsius = kelvin.to_f - 273.15
      else
        raise ArgumentError, "Either celsius, fahrenheit, or kelvin must be provided"
      end
    end

    def fahrenheit
      celsius_to_fahrenheit(@celsius)
    end

    def kelvin
      @celsius + 273.15
    end

    def <=>(other)
      return nil unless other.is_a?(Temperature)

      celsius <=> other.celsius
    end

    def to_h
      {
        celsius: celsius.round(1),
        fahrenheit: fahrenheit.round(1),
        kelvin: kelvin.round(1)
      }
    end

    def to_s
      "#{celsius.round(1)}°C (#{fahrenheit.round(1)}°F)"
    end

    private

    def celsius_to_fahrenheit(celsius)
      (celsius * 9.0 / 5.0) + 32.0
    end

    def fahrenheit_to_celsius(fahrenheit)
      (fahrenheit - 32.0) * 5.0 / 9.0
    end
  end
end
