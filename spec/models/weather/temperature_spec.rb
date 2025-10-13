# frozen_string_literal: true

require "rails_helper"

RSpec.describe Weather::Temperature, type: :model do
  describe "#initialize" do
    it "creates temperature from celsius" do
      temp = described_class.new(celsius: 20.0)

      expect(temp.celsius).to eq(20.0)
      expect(temp.fahrenheit).to be_within(0.1).of(68.0)
      expect(temp.kelvin).to be_within(0.1).of(293.15)
    end

    it "creates temperature from fahrenheit" do
      temp = described_class.new(fahrenheit: 68.0)

      expect(temp.celsius).to be_within(0.1).of(20.0)
      expect(temp.fahrenheit).to eq(68.0)
      expect(temp.kelvin).to be_within(0.1).of(293.15)
    end

    it "creates temperature from kelvin" do
      temp = described_class.new(kelvin: 293.15)

      expect(temp.celsius).to be_within(0.1).of(20.0)
      expect(temp.fahrenheit).to be_within(0.1).of(68.0)
      expect(temp.kelvin).to eq(293.15)
    end

    it "raises error without any temperature" do
      expect { described_class.new({}) }.to raise_error(ArgumentError)
    end
  end

  describe "#to_h" do
    it "returns hash with all units" do
      temp = described_class.new(celsius: 20.0)
      hash = temp.to_h

      expect(hash).to have_key(:celsius)
      expect(hash).to have_key(:fahrenheit)
      expect(hash).to have_key(:kelvin)
      expect(hash[:celsius]).to eq(20.0)
    end
  end

  describe "#to_s" do
    it "returns formatted string" do
      temp = described_class.new(celsius: 20.0)

      expect(temp.to_s).to include("20.0")
      expect(temp.to_s).to include("°C")
    end
  end

  describe "comparisons" do
    let(:temp1) { described_class.new(celsius: 20.0) }
    let(:temp2) { described_class.new(celsius: 25.0) }
    let(:temp3) { described_class.new(celsius: 20.0) }

    it "compares temperatures" do
      expect(temp1 < temp2).to be true
      expect(temp2 > temp1).to be true
      expect(temp1 == temp3).to be true
    end
  end

  describe "conversions" do
    it "converts freezing point correctly" do
      temp = described_class.new(celsius: 0.0)

      expect(temp.fahrenheit).to eq(32.0)
      expect(temp.kelvin).to be_within(0.01).of(273.15)
    end

    it "converts boiling point correctly" do
      temp = described_class.new(celsius: 100.0)

      expect(temp.fahrenheit).to eq(212.0)
      expect(temp.kelvin).to be_within(0.01).of(373.15)
    end
  end
end
