# frozen_string_literal: true

# Configure structured JSON logging via the Lumberjack gem in production.
#
# In development and test the default Rails text logger is preserved so that
# human-readable output is visible during local development and test runs.
#
# In production every log line is a single JSON object so log aggregators
# (Datadog, CloudWatch Logs Insights, Loki, Splunk, etc.) can filter and
# alert on individual fields without parsing unstructured text.
#
# The Lumberjack::Rack::Context middleware is inserted after
# ActionDispatch::RequestId so that action_dispatch.request_id is
# automatically stamped on every log entry emitted during a request.
return unless Rails.env.production?

json_template = lambda do |entry|
  payload = {
    time:     entry.time.iso8601(3),
    severity: entry.severity_label.downcase,
    pid:      entry.pid,
    message:  entry.message
  }
  attrs = entry.attributes
  payload.merge!(attrs) if attrs&.any?
  JSON.generate(payload)
end

Rails.logger = Lumberjack::Logger.new(
  $stdout,
  level:    ENV.fetch("RAILS_LOG_LEVEL", "info"),
  template: json_template
)

# Tag every log entry during a request with the Rails request ID so all
# lines from a single request are trivially correlated in the aggregator.
Rails.application.config.middleware.insert_after(
  ActionDispatch::RequestId,
  Lumberjack::Rack::Context,
  request_id: ->(env) { env["action_dispatch.request_id"] }
)
