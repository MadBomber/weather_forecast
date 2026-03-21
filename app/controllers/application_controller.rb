# frozen_string_literal: true

require "active_support/security_utils"

class ApplicationController < ActionController::API
  before_action :authenticate_request

  # Rails checks rescue_from handlers in reverse-definition order (last defined = checked first).
  # Define broad handlers first so specific ones take precedence.

  rescue_from StandardError do |e|
    Rails.logger.error("Unhandled error: #{e.class} — #{e.message}")
    render json: { error: "An unexpected error occurred." }, status: :internal_server_error
  end

  rescue_from ActionController::ParameterMissing do |e|
    render json: { error: e.message }, status: :bad_request
  end

  rescue_from Weather::BaseAdapter::ApiError do |e|
    Rails.logger.error("Weather API error: #{e.class} — #{e.message}")
    render json: { error: "Weather service unavailable. Please try again later." }, status: :service_unavailable
  end

  rescue_from Weather::BaseAdapter::RateLimitError do |e|
    Rails.logger.warn("Weather adapter rate limit hit: #{e.message}")
    render json: { error: "API rate limit exceeded. Please try again later." }, status: :too_many_requests
  end

  rescue_from Weather::BaseAdapter::LocationNotFoundError do |e|
    render json: { error: "Location not found: #{e.message}" }, status: :not_found
  end

  def not_found
    render json: { error: "Route not found" }, status: :not_found
  end

  private

  # Authenticate via X-API-Key header.
  #
  # When API_KEYS env var is empty or unset the API is open (development / PoC mode).
  # Set API_KEYS=key1,key2 in production to require authentication.
  #
  # The health-check endpoint (/up) is always public.
  def authenticate_request
    return if request.path == "/up" || request.path.start_with?("/up.")

    valid_keys = ENV.fetch("API_KEYS", "").split(",").map(&:strip).reject(&:empty?)
    return if valid_keys.empty?

    provided_key = request.headers["X-API-Key"].to_s

    if provided_key.blank?
      Rails.logger.warn("Auth: missing API key — ip=#{request.remote_ip} path=#{request.path}")
      return render json: { error: "Unauthorized. Provide a valid X-API-Key header." }, status: :unauthorized
    end

    return if valid_keys.any? { |k| ActiveSupport::SecurityUtils.secure_compare(provided_key, k) }

    Rails.logger.warn("Auth: invalid API key — ip=#{request.remote_ip} key_prefix=#{provided_key.first(4)} path=#{request.path}")
    render json: { error: "Unauthorized. Provide a valid X-API-Key header." }, status: :unauthorized
  end
end
