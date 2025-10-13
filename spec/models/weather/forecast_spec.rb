# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::Forecast, type: :model do
  let(:valid_attributes) do
    {
      location: "London",
      timestamp: Time.current,
      temperature: { celsius: 20.0 },
      conditions: "Sunny",
      description: "Clear skies",
      humidity: 65.0,
      wind_speed: 10.5,
      wind_direction: "N",
      precipitation_chance: 0.0
    }
  end

  describe "#initialize" do
    it "creates a forecast with valid attributes" do
      forecast = described_class.new(**valid_attributes)

      expect(forecast.location).to eq("London")
      expect(forecast.conditions).to eq("Sunny")
      expect(forecast.humidity).to eq(65.0)
      expect(forecast.wind_speed).to eq(10.5)
      expect(forecast.wind_direction).to eq("N")
      expect(forecast.precipitation_chance).to eq(0.0)
    end

    it "creates temperature object from hash" do
      forecast = described_class.new(**valid_attributes)

      expect(forecast.temperature).to be_a(Weather::Temperature)
      expect(forecast.temperature.celsius).to eq(20.0)
    end

    it "accepts string timestamp" do
      attributes = valid_attributes.merge(timestamp: "2025-10-12T10:00:00Z")
      forecast = described_class.new(**attributes)

      expect(forecast.timestamp).to be_a(Time)
    end
  end

  describe "#to_h" do
    it "converts forecast to hash" do
      forecast = described_class.new(**valid_attributes)
      hash = forecast.to_h

      expect(hash).to be_a(Hash)
      expect(hash[:location]).to eq("London")
      expect(hash[:conditions]).to eq("Sunny")
      expect(hash[:temperature]).to be_a(Hash)
      expect(hash[:temperature][:celsius]).to eq(20.0)
    end

    it "includes timestamp in ISO8601 format" do
      forecast = described_class.new(**valid_attributes)
      hash = forecast.to_h

      expect(hash[:timestamp]).to be_a(String)
      expect { Time.parse(hash[:timestamp]) }.not_to raise_error
    end
  end

  describe "#to_json" do
    it "converts forecast to JSON string" do
      forecast = described_class.new(**valid_attributes)
      json = forecast.to_json

      expect(json).to be_a(String)
      parsed = JSON.parse(json)
      expect(parsed["location"]).to eq("London")
      expect(parsed["conditions"]).to eq("Sunny")
    end
  end
end
