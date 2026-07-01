#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/deployment/server.env"
PID_DIR="$ROOT_DIR/.local-run/pids"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

: "${AI_SERVICE_HOST:=0.0.0.0}"
: "${AI_SERVICE_PORT:=8000}"

kill_pattern() {
  local name="$1"
  local pattern="$2"
  local pids
  pids="$(pgrep -f "$pattern" || true)"
  if [[ -z "$pids" ]]; then
    echo "No matching $name process found."
    return 0
  fi

  echo "Stopping $name processes: $pids"
  while read -r pid; do
    [[ -z "$pid" ]] && continue
    kill "$pid" >/dev/null 2>&1 || true
  done <<< "$pids"

  sleep 1

  local remaining
  remaining="$(pgrep -f "$pattern" || true)"
  if [[ -n "$remaining" ]]; then
    echo "$name still running after SIGTERM, sending SIGKILL: $remaining"
    while read -r pid; do
      [[ -z "$pid" ]] && continue
      kill -9 "$pid" >/dev/null 2>&1 || true
    done <<< "$remaining"
  fi
}

rm -f "$PID_DIR/frontend.pid" "$PID_DIR/backend.pid" "$PID_DIR/ai-service.pid"

kill_pattern "Frontend" "$ROOT_DIR/frontend/node_modules/.bin/vite --host 0.0.0.0 --port"
kill_pattern "Backend launcher" "$ROOT_DIR/backend.*spring-boot:run -Dspring-boot.run.profiles="
kill_pattern "Backend app" "com.example.learning.OnlineLearningApplication --spring.profiles.active="
kill_pattern "AI service" "python3 -m uvicorn app.main:app --host ${AI_SERVICE_HOST} --port ${AI_SERVICE_PORT}"

echo "Local application processes cleaned. MySQL and Redis were left running."
