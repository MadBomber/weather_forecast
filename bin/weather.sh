#!/usr/bin/env bash
# Get weather forecast for a specified location

set -e

# Check if location argument is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <location>"
  echo ""
  echo "Examples:"
  echo "  $0 London"
  echo "  $0 90210"
  echo "  $0 \"New York\""
  echo "  $0 51.5074,-0.1278"
  exit 1
fi

# Get the location from the first argument
LOCATION="$1"

# Default API endpoint
API_HOST="${API_HOST:-localhost}"
API_PORT="${API_PORT:-3000}"
API_URL="http://${API_HOST}:${API_PORT}/api/v1/forecast"

# URL encode the location parameter
ENCODED_LOCATION=$(printf %s "$LOCATION" | jq -sRr @uri)

# Make the request
curl -s "${API_URL}?location=${ENCODED_LOCATION}"
