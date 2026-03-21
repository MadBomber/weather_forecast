# frozen_string_literal: true

# Rate limiting configuration using Rack::Attack.
# Reuses the existing Redis cache store — no additional infrastructure needed.
#
# Limits:
#   - 60 requests per minute per IP on all API routes
#   - 10 requests per 10 seconds per IP (burst protection)
#
# Override via environment variables:
#   RATE_LIMIT_API_RPM   - requests per minute (default: 60)
#   RATE_LIMIT_BURST_RPS - requests per 10 seconds (default: 10)

Rack::Attack.cache.store = Rails.cache

api_rpm   = ENV.fetch("RATE_LIMIT_API_RPM", 60).to_i
burst_rps = ENV.fetch("RATE_LIMIT_BURST_RPS", 10).to_i

# Sustained rate limit — 60 requests per minute per IP
Rack::Attack.throttle("api/ip/minute", limit: api_rpm, period: 1.minute) do |req|
  req.ip if req.path.start_with?("/api/")
end

# Burst protection — 10 requests per 10 seconds per IP
Rack::Attack.throttle("api/ip/burst", limit: burst_rps, period: 10.seconds) do |req|
  req.ip if req.path.start_with?("/api/")
end

# Return JSON instead of the default plain-text 429 response
Rack::Attack.throttled_responder = lambda do |req|
  match_data = req.env["rack.attack.match_data"]
  retry_after = match_data ? match_data[:period] : 60

  [
    429,
    {
      "Content-Type" => "application/json",
      "Retry-After"  => retry_after.to_s
    },
    [ { error: "Rate limit exceeded. Please try again later.", retry_after: retry_after }.to_json ]
  ]
end
