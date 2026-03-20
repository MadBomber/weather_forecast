# frozen_string_literal: true

# CORS configuration for the Weather Forecast API.
#
# By default all origins are permitted (suitable for a public read-only API).
# Set CORS_ALLOWED_ORIGINS to a comma-separated list of domains in production
# to restrict access:
#
#   CORS_ALLOWED_ORIGINS=https://myapp.com,https://app.myapp.com
#
Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins do |source, _env|
      allowed = ENV.fetch("CORS_ALLOWED_ORIGINS", "*")
      allowed == "*" || allowed.split(",").map(&:strip).include?(source)
    end

    resource "/api/*",
      headers: :any,
      methods: [ :get, :options ],
      expose: [ "X-Request-Id" ],
      max_age: 600
  end

  # Health check endpoint accessible from any origin
  allow do
    origins "*"
    resource "/up", headers: :any, methods: [ :get ]
  end
end
