#!/usr/bin/env bash
# Flush all cached weather data from Redis

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

# Redis connection info from environment or defaults
REDIS_URL="${REDIS_URL:-redis://localhost:6379/0}"

echo "Flushing weather cache from Redis..."
echo "Redis URL: $REDIS_URL"

# Extract host, port, and database from REDIS_URL
# Format: redis://host:port/db
if [[ $REDIS_URL =~ redis://([^:]+):([0-9]+)/([0-9]+) ]]; then
  REDIS_HOST="${BASH_REMATCH[1]}"
  REDIS_PORT="${BASH_REMATCH[2]}"
  REDIS_DB="${BASH_REMATCH[3]}"
elif [[ $REDIS_URL =~ redis://([^:]+):([0-9]+) ]]; then
  REDIS_HOST="${BASH_REMATCH[1]}"
  REDIS_PORT="${BASH_REMATCH[2]}"
  REDIS_DB="0"
else
  REDIS_HOST="localhost"
  REDIS_PORT="6379"
  REDIS_DB="0"
fi

# Count weather keys before flushing
KEYS_OUTPUT=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -n "$REDIS_DB" KEYS "weather:*")

if [ -z "$KEYS_OUTPUT" ]; then
  echo "No weather cache keys found"
  exit 0
fi

KEY_COUNT=$(echo "$KEYS_OUTPUT" | wc -l | tr -d ' ')

echo "Found $KEY_COUNT weather cache key(s)"

# Delete all weather-related keys
# Using KEYS + DEL - suitable for development/maintenance scripts
# For production with large keyspaces, consider using SCAN instead
redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -n "$REDIS_DB" KEYS "weather:*" | while read -r key; do
  if [ -n "$key" ]; then
    redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -n "$REDIS_DB" DEL "$key" > /dev/null
  fi
done

# Verify deletion
REMAINING_OUTPUT=$(redis-cli -h "$REDIS_HOST" -p "$REDIS_PORT" -n "$REDIS_DB" KEYS "weather:*")

if [ -z "$REMAINING_OUTPUT" ]; then
  echo "Weather cache flushed successfully ($KEY_COUNT key(s) deleted)"
else
  REMAINING=$(echo "$REMAINING_OUTPUT" | wc -l | tr -d ' ')
  echo "Warning: Some keys may remain ($REMAINING key(s))"
  exit 1
fi
