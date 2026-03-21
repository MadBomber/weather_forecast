# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::AdapterFactory, type: :service do
  describe ".build" do
    context "with default adapter" do
      around do |example|
        original = ENV["WEATHER_ADAPTER"]
        ENV.delete("WEATHER_ADAPTER")
        example.run
        ENV["WEATHER_ADAPTER"] = original
      end

      it "returns an OpenWeatherMapAdapter when WEATHER_ADAPTER is not set" do
        adapter = described_class.build

        expect(adapter).to be_a(Weather::OpenWeatherMapAdapter)
      end
    end

    context "with WEATHER_ADAPTER env var set" do
      around do |example|
        original = ENV["WEATHER_ADAPTER"]
        ENV["WEATHER_ADAPTER"] = "Weather::OpenWeatherMapAdapter"
        example.run
        ENV["WEATHER_ADAPTER"] = original
      end

      it "returns the configured adapter class" do
        adapter = described_class.build
        expect(adapter).to be_a(Weather::OpenWeatherMapAdapter)
      end
    end

    context "with an unknown adapter class" do
      around do |example|
        original = ENV["WEATHER_ADAPTER"]
        ENV["WEATHER_ADAPTER"] = "Weather::NonExistentAdapter"
        example.run
        ENV["WEATHER_ADAPTER"] = original
      end

      it "raises ArgumentError with a descriptive message" do
        expect {
          described_class.build
        }.to raise_error(ArgumentError, /Unknown weather adapter.*NonExistentAdapter/)
      end
    end
  end
end
