#!/usr/bin/env bash
# Stop the Weather Forecast API server

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Change to project root
cd "$PROJECT_ROOT"

# PID file location
PID_FILE="tmp/pids/server.pid"

# Check if PID file exists
if [ ! -f "$PID_FILE" ]; then
  echo "Server is not running (no PID file found)"

  # Check if anything is running on port 3000
  if lsof -ti:3000 > /dev/null 2>&1; then
    echo "But found process(es) on port 3000. Attempting to kill..."
    lsof -ti:3000 | xargs kill -9 2>/dev/null || true
    echo "Processes on port 3000 have been terminated"
  fi

  exit 0
fi

# Read the PID
PID=$(cat "$PID_FILE")

# Check if the process is running
if ! ps -p "$PID" > /dev/null 2>&1; then
  echo "Server is not running (PID $PID not found)"
  rm -f "$PID_FILE"

  # Check if anything is running on port 3000
  if lsof -ti:3000 > /dev/null 2>&1; then
    echo "But found process(es) on port 3000. Attempting to kill..."
    lsof -ti:3000 | xargs kill -9 2>/dev/null || true
    echo "Processes on port 3000 have been terminated"
  fi

  exit 0
fi

echo "Stopping Weather Forecast API server (PID: $PID)..."

# Try graceful shutdown first
kill -TERM "$PID" 2>/dev/null || true

# Wait up to 5 seconds for graceful shutdown
for i in {1..5}; do
  if ! ps -p "$PID" > /dev/null 2>&1; then
    echo "Server stopped successfully"
    rm -f "$PID_FILE"
    exit 0
  fi
  sleep 1
done

# If still running, force kill
if ps -p "$PID" > /dev/null 2>&1; then
  echo "Forcing server shutdown..."
  kill -9 "$PID" 2>/dev/null || true
  sleep 1
fi

# Clean up PID file
rm -f "$PID_FILE"

# Final check
if lsof -ti:3000 > /dev/null 2>&1; then
  echo "Cleaning up remaining processes on port 3000..."
  lsof -ti:3000 | xargs kill -9 2>/dev/null || true
fi

echo "Server stopped"
