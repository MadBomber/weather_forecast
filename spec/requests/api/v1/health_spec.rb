# frozen_string_literal: true

require "rails_helper"

RSpec.describe "GET /api/v1/health", type: :request do
  def do_get
    get "/api/v1/health"
  end

  context "when Redis and API key are available" do
    before do
      allow(Rails.cache).to receive(:write).and_return(true)
      stub_const("ENV", ENV.to_h.merge("OPENWEATHERMAP_API_KEY" => "test_key"))
    end

    it "returns 200" do
      do_get
      expect(response).to have_http_status(:ok)
    end

    it "reports status ok" do
      do_get
      expect(JSON.parse(response.body)["status"]).to eq("ok")
    end

    it "reports both checks as ok" do
      do_get
      checks = JSON.parse(response.body)["checks"]
      expect(checks["redis"]["ok"]).to be true
      expect(checks["weather_adapter"]["ok"]).to be true
    end
  end

  context "when Redis is unavailable" do
    before do
      allow_any_instance_of(Api::V1::HealthController).to receive(:check_redis)
        .and_return({ ok: false, error: "Connection refused" })
      stub_const("ENV", ENV.to_h.merge("OPENWEATHERMAP_API_KEY" => "test_key"))
    end

    it "returns 503" do
      do_get
      expect(response).to have_http_status(:service_unavailable)
    end

    it "reports status degraded" do
      do_get
      expect(JSON.parse(response.body)["status"]).to eq("degraded")
    end

    it "reports redis check as failed" do
      do_get
      checks = JSON.parse(response.body)["checks"]
      expect(checks["redis"]["ok"]).to be false
      expect(checks["redis"]["error"]).to be_present
    end
  end

  context "when the API key is not configured" do
    before do
      allow(Rails.cache).to receive(:write).and_return(true)
      stub_const("ENV", ENV.to_h.except("OPENWEATHERMAP_API_KEY"))
    end

    it "returns 503" do
      do_get
      expect(response).to have_http_status(:service_unavailable)
    end

    it "reports weather_adapter check as failed" do
      do_get
      checks = JSON.parse(response.body)["checks"]
      expect(checks["weather_adapter"]["ok"]).to be false
      expect(checks["weather_adapter"]["error"]).to eq("API key not configured")
    end
  end

  context "when API_KEYS authentication is enabled" do
    around do |example|
      original = ENV["API_KEYS"]
      ENV["API_KEYS"] = "some_key"
      example.run
      ENV["API_KEYS"] = original
    end

    it "is accessible without an API key" do
      do_get
      expect(response).not_to have_http_status(:unauthorized)
    end
  end
end
