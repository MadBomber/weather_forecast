source "https://rubygems.org"

gem "rails", "~> 8.0.3"
gem "bootsnap", require: false
gem "falcon-rails"
gem "rack-attack"
gem "rack-cors"
gem "redis"
gem "breaker_machines"
gem "lumberjack"
gem "lumberjack_json_device"
gem "lumberjack_rails"

gem "dotenv-rails"

group :development, :test do
  gem "debug_me"
  gem "aigcm"
end

group :development do
  gem "brakeman", require: false
  gem "claude-on-rails"
  gem "overcommit", require: false
  gem "rubocop-rails"
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "rspec-rails"
  gem "simplecov", require: false
  gem "vcr"
  gem "webmock"
end
