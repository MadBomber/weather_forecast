# frozen_string_literal: true

module Api
  module V1
    # Deep health check endpoint.
    # GET /api/v1/health
    #
    # Returns 200 when all dependencies are operational, 503 if any check fails.
    # Distinct from /up (which only confirms the Rails process is alive) so that
    # load balancers can use /up while monitoring systems use /api/v1/health.
    class HealthController < ApplicationController
      skip_before_action :authenticate_request

      def show
        checks = {
          redis: check_redis,
          weather_adapter: check_weather_adapter
        }

        all_ok = checks.values.all? { |c| c[:ok] }
        render json: { status: (all_ok ? "ok" : "degraded"), checks: checks },
               status: (all_ok ? :ok : :service_unavailable)
      end

      private

      def check_redis
        Rails.cache.write("health_check", "ok", expires_in: 5.seconds)
        { ok: true }
      rescue => e
        { ok: false, error: e.message }
      end

      def check_weather_adapter
        if ENV["OPENWEATHERMAP_API_KEY"].present?
          { ok: true }
        else
          { ok: false, error: "API key not configured" }
        end
      end
    end
  end
end
