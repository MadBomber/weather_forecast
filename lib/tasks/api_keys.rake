# frozen_string_literal: true

namespace :api_keys do
  desc "Generate a new random API key suitable for use in API_KEYS env var"
  task generate: :environment do
    key = SecureRandom.hex(32)
    puts <<~HEREDOC
      Generated API key: #{key}

      Add it to your API_KEYS environment variable (comma-separated for multiple keys):
        API_KEYS=#{key}

      Clients must send this key in the X-API-Key request header:
        curl -H "X-API-Key: #{key}" http://localhost:3000/api/v1/current?location=London
    HEREDOC
  end
end
