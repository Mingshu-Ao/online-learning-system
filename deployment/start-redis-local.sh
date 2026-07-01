#!/usr/bin/env bash
set -euo pipefail

if ! command -v redis-server >/dev/null 2>&1; then
  echo "redis-server is not installed." >&2
  echo "Install it first, for example:" >&2
  echo "  apt-get update && apt-get install -y redis-server" >&2
  exit 1
fi

if command -v redis-cli >/dev/null 2>&1 && redis-cli ping >/dev/null 2>&1; then
  echo "Redis is already running."
  exit 0
fi

if command -v service >/dev/null 2>&1; then
  service redis-server start >/dev/null 2>&1 || true
fi

if command -v redis-cli >/dev/null 2>&1 && redis-cli ping >/dev/null 2>&1; then
  echo "Redis started with service redis-server start."
  exit 0
fi

redis-server --daemonize yes

for _ in {1..10}; do
  if command -v redis-cli >/dev/null 2>&1 && redis-cli ping >/dev/null 2>&1; then
    echo "Redis started successfully."
    exit 0
  fi
  sleep 1
done

echo "Failed to start Redis." >&2
exit 1
