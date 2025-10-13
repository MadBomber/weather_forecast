#!/usr/bin/env bash
# Start the Weather Forecast API server

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

# PID file location
PID_FILE="tmp/pids/server.pid"

# Check if server is already running
if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE")
  if ps -p "$PID" > /dev/null 2>&1; then
    echo "Server is already running (PID: $PID)"
    echo "Use bin/stop.sh to stop it first"
    exit 1
  else
    echo "Removing stale PID file"
    rm -f "$PID_FILE"
  fi
fi

# Create tmp/pids directory if it doesn't exist
mkdir -p tmp/pids

# Set default environment if not specified
export RAILS_ENV="${RAILS_ENV:-development}"

echo "Starting Weather Forecast API server..."
echo "Environment: $RAILS_ENV"
echo "Binding to: http://localhost:3000"

# Start the server in the background
bundle exec falcon serve --bind http://localhost:3000 > log/server.log 2>&1 &

# Save the PID
SERVER_PID=$!
echo "$SERVER_PID" > "$PID_FILE"

# Wait a moment for the server to start
sleep 2

# Check if the server is running
if ps -p "$SERVER_PID" > /dev/null 2>&1; then
  echo "Server started successfully (PID: $SERVER_PID)"
  echo "Logs: log/server.log"
  echo "Stop with: bin/stop.sh"
else
  echo "Failed to start server"
  rm -f "$PID_FILE"
  exit 1
fi
