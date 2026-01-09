source "https://rubygems.org"

gem "rails", "~> 8.1.2"
gem "bootsnap", require: false
gem "falcon-rails"
gem "redis"

gem "openweathermap"
gem "dotenv-rails"

group :development, :test do
  gem "debug_me"
end

group :development do
  gem "brakeman", require: false
  gem "claude-on-rails"
  gem "rubocop-rails"
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "rspec-rails"
  gem "webmock"
end
