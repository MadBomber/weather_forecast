source "https://rubygems.org"

gem "rails", "~> 8.0.3"
gem "bootsnap", require: false
gem "falcon-rails"
gem "redis"
gem "rubocop"

gem "openweathermap"

group :development, :test do
  gem "claude-on-rails"
  gem "debug_me"

  # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "brakeman", require: false
end

group :test do
  gem "rspec-rails"
end
