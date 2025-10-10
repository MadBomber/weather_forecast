source "https://rubygems.org"

gem "rails", "~> 8.0.3"
gem "falcon-rails", "~> 0.2.4"

gem "redis"


# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false



group :development, :test do
  gem "claude-on-rails"
  gem "debug_me"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false
end

group :test do
  gem "rspec-rails"
end

gem "nws_openapi_sdk", "~> 0.1.0"

gem "openweathermap", "~> 0.2.3"
