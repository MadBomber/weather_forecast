#!/usr/bin/env ruby
# frozen_string_literal: true

# examples/01_basic_usage.rb
#
# Demonstrates basic usage of the WeatherForecast Rails API.
#
# If the API server is not already running on localhost:3000 this script starts
# it automatically and stops it when done.  If the server was already running
# it is left running after the demo completes.
#
# Usage:
#   ruby examples/01_basic_usage.rb
#
# The OPENWEATHERMAP_API_KEY environment variable must be set (or present in
# .env.local) for live responses.  Set API_KEYS if the server is running with
# authentication enabled.

require "net/http"
require "json"
require "uri"

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

API_BASE     = "http://localhost:3000/api/v1"
HEALTH_BASIC = "http://localhost:3000/up"
HEALTH_DEEP  = "#{API_BASE}/health"
PROJECT      = File.expand_path("..", __dir__)
PID_FILE     = File.join(PROJECT, "tmp", "pids", "server.pid")

# Optional: include X-API-Key if the server requires authentication.
API_KEY = ENV.fetch("API_KEYS", "").split(",").first&.strip

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

SEPARATOR = "─" * 60

def header(title)
  puts
  puts SEPARATOR
  puts "  #{title}"
  puts SEPARATOR
end

def server_running?
  uri  = URI(HEALTH_BASIC)
  http = Net::HTTP.new(uri.host, uri.port)
  http.open_timeout = 2
  http.read_timeout = 3
  http.get(uri.path.empty? ? "/" : uri.path).is_a?(Net::HTTPSuccess)
rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT, SocketError,
       Net::OpenTimeout, Net::ReadTimeout
  false
end

# Returns true when a server process is alive (PID file exists + kill(0) succeeds)
# but it has not yet started accepting HTTP connections.
def server_process_alive?
  return false unless File.exist?(PID_FILE)

  pid = File.read(PID_FILE).strip.to_i
  return false if pid.zero?

  Process.kill(0, pid)
  true
rescue Errno::ESRCH  # no such process
  false
rescue Errno::EPERM  # process exists but owned by another user
  true
end

# Poll /up until it responds or the timeout (seconds) is exhausted.
# Prints a dot each second so the user sees progress.
def wait_for_boot(timeout: 30)
  print "  Waiting for Rails to finish booting"
  $stdout.flush

  result = timeout.times.any? do
    sleep 1
    print "."
    $stdout.flush
    server_running?
  end

  puts
  result
end

def build_request(path, params = {}, key: API_KEY)
  uri       = URI("#{API_BASE}/#{path}")
  uri.query = URI.encode_www_form(params) unless params.empty?
  req       = Net::HTTP::Get.new(uri)
  req["Accept"]    = "application/json"
  req["X-API-Key"] = key if key && !key.empty?
  [ uri, req ]
end

def fetch(path, params = {}, key: API_KEY)
  uri, req = build_request(path, params, key: key)
  Net::HTTP.start(uri.host, uri.port) { |http| http.request(req) }
end

def pretty_temp(temp_hash)
  "#{temp_hash["celsius"]}°C / #{temp_hash["fahrenheit"]}°F"
end

def print_current(json)
  d = json["data"]
  p = json["performance"]

  puts "  Location    : #{d["location"]}"
  puts "  Timestamp   : #{d["timestamp"]}"
  puts "  Temperature : #{pretty_temp(d["temperature"])}"
  puts "  Conditions  : #{d["conditions"]}#{d["description"] ? " (#{d["description"]})" : ""}"
  puts "  Humidity    : #{d["humidity"]}%" if d["humidity"]
  puts "  Wind        : #{d["wind_speed"]} m/s #{d["wind_direction"]}" if d["wind_speed"]
  puts "  Precip.     : #{d["precipitation_chance"]}%" if d["precipitation_chance"]
  puts "  Cached      : #{p["cached"]}"
  puts "  Duration    : #{p["duration_ms"]} ms"
end

def print_forecast_day(entry)
  ts   = entry["timestamp"][0, 10]
  temp = pretty_temp(entry["temperature"])
  cond = entry["conditions"]
  desc = entry["description"] ? " (#{entry["description"]})" : ""
  puts "    #{ts}  #{temp.ljust(24)} #{cond}#{desc}"
end

def print_health(json, http_code)
  status_label = http_code == "200" ? "✓ ok" : "✗ degraded"
  puts "  Overall status : #{status_label} (HTTP #{http_code})"
  puts

  json["checks"].each do |name, result|
    icon = result["ok"] ? "✓" : "✗"
    line = "  #{icon} #{name.ljust(18)}: #{result["ok"] ? "ok" : result["error"]}"
    puts line
  end
end

# ---------------------------------------------------------------------------
# Server lifecycle
# ---------------------------------------------------------------------------

we_started_server = false

header("Server check")

if server_running?
  # Fully up and responding — leave it running when we finish.
  puts "  Rails API is already running — will leave it running after the demo."

elsif server_process_alive?
  # Process is alive but still booting (e.g. left over from a previous run).
  # Don't start a second server — just wait for it to become ready.
  puts "  Server process is running but not yet accepting connections — waiting..."
  unless wait_for_boot(timeout: 30)
    abort "  ERROR: Server process never became ready — check log/server.log"
  end
  puts "  Rails API is ready."
  # We didn't start this process so we won't stop it when done.

else
  # Truly not running — start it.
  puts "  Rails API is not running — starting it now..."
  start_script = File.join(PROJECT, "bin", "start.sh")

  unless File.executable?(start_script)
    abort "  ERROR: #{start_script} not found or not executable"
  end

  # Run start.sh synchronously so output is visible and exit code is checked.
  # start.sh launches Falcon in the background, sleeps 2 s, and exits non-zero
  # if the process failed to start.
  # RAILS_LOG_LEVEL=info ensures Rails logger accepts info-level events.
  # CONSOLE_LEVEL=info tells the Console gem (brought in by falcon-rails) to
  # forward info-level messages; its default is warn, which would silence the
  # weather.current / weather.forecast structured log events.
  unless system({ "RAILS_LOG_LEVEL" => "info", "CONSOLE_LEVEL" => "info" }, "bash", start_script, chdir: PROJECT)
    abort "  ERROR: bin/start.sh failed — check log/server.log"
  end

  # Falcon process is alive; wait for Rails to finish booting.
  unless wait_for_boot(timeout: 30)
    abort "  ERROR: Server process started but /up never responded.\n" \
          "  Check log/server.log for details."
  end

  we_started_server = true
  puts "  Rails API is ready."
end

# ---------------------------------------------------------------------------
# Demo 1 — Current weather (cache miss)
# ---------------------------------------------------------------------------

header("Demo 1 · Current weather — London (cache miss)")

response = fetch("current", { location: "London" })
json     = JSON.parse(response.body)

if response.is_a?(Net::HTTPOK)
  print_current(json)
else
  puts "  HTTP #{response.code}: #{json["error"]}"
end

# ---------------------------------------------------------------------------
# Demo 2 — Current weather (cache hit)
# ---------------------------------------------------------------------------

header("Demo 2 · Current weather — London (cache hit)")
puts "  Repeating the same request — should be served from Redis cache."
puts

response = fetch("current", { location: "London" })
json     = JSON.parse(response.body)

if response.is_a?(Net::HTTPOK)
  print_current(json)
else
  puts "  HTTP #{response.code}: #{json["error"]}"
end

# ---------------------------------------------------------------------------
# Demo 3 — Current weather for a second city
# ---------------------------------------------------------------------------

header("Demo 3 · Current weather — Tokyo")

response = fetch("current", { location: "Tokyo" })
json     = JSON.parse(response.body)

if response.is_a?(Net::HTTPOK)
  print_current(json)
else
  puts "  HTTP #{response.code}: #{json["error"]}"
end

# ---------------------------------------------------------------------------
# Demo 4 — Coordinate-based lookup
# ---------------------------------------------------------------------------

header("Demo 4 · Current weather by coordinates (New York City)")
puts "  Using lat/lon: 40.7128,-74.0060"
puts

response = fetch("current", { location: "40.7128,-74.0060" })
json     = JSON.parse(response.body)

if response.is_a?(Net::HTTPOK)
  print_current(json)
else
  puts "  HTTP #{response.code}: #{json["error"]}"
end

# ---------------------------------------------------------------------------
# Demo 5 — Multi-day forecast
# ---------------------------------------------------------------------------

header("Demo 5 · 3-day forecast — Paris")

response = fetch("forecast", { location: "Paris", days: 3 })
json     = JSON.parse(response.body)

if response.is_a?(Net::HTTPOK)
  p = json["performance"]
  puts "  Cached: #{p["cached"]}   Duration: #{p["duration_ms"]} ms"
  puts
  puts "  Date        Temperature              Conditions"
  puts "  #{"─" * 56}"
  json["data"].each { |entry| print_forecast_day(entry) }
else
  puts "  HTTP #{response.code}: #{json["error"]}"
end

# ---------------------------------------------------------------------------
# Demo 6 — Validation: missing location
# ---------------------------------------------------------------------------

header("Demo 6 · Validation — missing location parameter")

response = fetch("current")
json     = JSON.parse(response.body)

puts "  HTTP status : #{response.code}"
puts "  Error       : #{json["error"]}"

# ---------------------------------------------------------------------------
# Demo 7 — Process health check (/up)
# ---------------------------------------------------------------------------

header("Demo 7 · Process health check (/up)")
puts "  Used by load balancers — only confirms the Rails process is alive."
puts

uri      = URI(HEALTH_BASIC)
response = Net::HTTP.get_response(uri)
puts "  GET /up  →  HTTP #{response.code} #{response.message}"

# ---------------------------------------------------------------------------
# Demo 8 — Deep health check (/api/v1/health)
# ---------------------------------------------------------------------------

header("Demo 8 · Deep health check (/api/v1/health)")
puts "  Probes Redis connectivity and OWM API key configuration."
puts "  Returns 200 when fully operational, 503 if any dependency is down."
puts "  No API key required — safe for monitoring systems."
puts

response = fetch("health")
json     = JSON.parse(response.body)
print_health(json, response.code)

# ---------------------------------------------------------------------------
# Demo 9 — Authentication (when API_KEYS is configured)
# ---------------------------------------------------------------------------

header("Demo 9 · Authentication")

valid_keys = ENV.fetch("API_KEYS", "").split(",").map(&:strip).reject(&:empty?)

if valid_keys.empty?
  puts "  API_KEYS is not set — server is running in open mode (no auth required)."
  puts "  Set API_KEYS=key1,key2 to enable authentication."
else
  puts "  API_KEYS is configured — demonstrating auth enforcement."
  puts

  # Missing key
  response = fetch("current", { location: "London" }, key: nil)
  puts "  Missing X-API-Key  →  HTTP #{response.code} #{JSON.parse(response.body)["error"]}"
  puts "  (Warning logged server-side with IP and path)"
  puts

  # Invalid key
  response = fetch("current", { location: "London" }, key: "invalid_key_xxxx")
  puts "  Invalid X-API-Key  →  HTTP #{response.code} #{JSON.parse(response.body)["error"]}"
  puts "  (Warning logged server-side with IP, path, and key prefix)"
  puts

  # Valid key
  response = fetch("current", { location: "London" }, key: valid_keys.first)
  puts "  Valid X-API-Key    →  HTTP #{response.code} (authenticated successfully)"
end

# ---------------------------------------------------------------------------
# Demo 10 — Configurable adapter (AdapterFactory)
# ---------------------------------------------------------------------------

header("Demo 10 · Configurable weather adapter")
puts "  The server resolves its weather provider via the WEATHER_ADAPTER env var."
puts "  Default: Weather::OpenWeatherMapAdapter"
puts "  Override: WEATHER_ADAPTER=Weather::SomeOtherAdapter"
puts
active_adapter = ENV.fetch("WEATHER_ADAPTER", "Weather::OpenWeatherMapAdapter")
puts "  Active adapter : #{active_adapter}"
puts "  Add new providers by subclassing Weather::BaseAdapter — zero controller changes."

# ---------------------------------------------------------------------------
# Teardown
# ---------------------------------------------------------------------------

puts
puts SEPARATOR

if we_started_server
  puts "  Demo complete — stopping the Rails API server..."
  stop_script = File.join(PROJECT, "bin", "stop.sh")
  system("bash", stop_script, chdir: PROJECT, out: File::NULL, err: File::NULL)
  puts "  Server stopped."
else
  puts "  Demo complete — Rails API server left running."
end

puts SEPARATOR
puts
