require "active_support/core_ext/integer/time"

# This is an API-only application with no database (ADR-0005) and no Action Mailer,
# Active Storage, Action Cable, or Active Job in use. Only relevant production settings
# are configured here; unused framework stubs have been removed to avoid confusion.
Rails.application.configure do
  # Code is not reloaded between requests.
  config.enable_reloading = false

  # Eager load code on boot for better performance and memory savings (ignored by Rake tasks).
  config.eager_load = true

  # Full error reports are disabled.
  config.consider_all_requests_local = false

  # Assume all access to the app is happening through a SSL-terminating reverse proxy.
  config.assume_ssl = true

  # Force all access to the app over SSL, use Strict-Transport-Security, and use secure cookies.
  config.force_ssl = true

  # Structured JSON logging via lumberjack_rails + lumberjack_json_device.
  # Every log line is a single JSON object so aggregators (Datadog, CloudWatch
  # Logs Insights, Loki) can filter and alert on individual fields.
  #
  # attributes: "*" flattens structured fields (location, cached, duration_ms,
  # request_id) to the root JSON object rather than nesting them under "attributes".
  require "lumberjack_json_device"
  config.lumberjack.device = Lumberjack::JsonDevice.new(
    $stdout,
    mapping: {
      time:       "time",
      severity:   "level",
      pid:        "pid",
      message:    "message",
      attributes: "*"
    },
    datetime_format: "%Y-%m-%dT%H:%M:%S.%3NZ",
    utc: true
  )

  # Stamp every log entry with the Rails request ID so all lines from a single
  # request are trivially correlated in the aggregator.
  config.lumberjack.request_attributes_proc = ->(request) { { request_id: request.request_id } }

  # Silence the noisy "Started GET ..." rack logger line — the structured
  # weather.current / weather.forecast events carry the same information.
  config.lumberjack.silence_rack_request_started = true

  # Change to "debug" to log everything (including potentially personally-identifiable information!)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")

  # Prevent health checks from clogging up the logs.
  config.silence_healthcheck_path = "/up"

  # Don't log any deprecations.
  config.active_support.report_deprecations = false

  # Use Redis for caching in production (configured via REDIS_URL).
  config.cache_store = :redis_cache_store, { url: ENV.fetch("REDIS_URL", "redis://localhost:6379/0") }

  # Enable DNS rebinding protection and other `Host` header attacks.
  # config.hosts = [
  #   "example.com",
  #   /.*\.example\.com/
  # ]
end
