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

: "${AI_SERVICE_PORT:=8000}"
: "${SERVER_PORT:=8080}"
: "${FRONTEND_PORT:=5173}"

find_existing_pid() {
  local pattern="$1"
  pgrep -f "$pattern" | head -n 1 || true
}

report_service() {
  local name="$1"
  local pid_file="$2"
  local url="$3"
  local process_pattern="$4"
  local pid_status="not managed"
  local http_status="unreachable"

  if [[ -f "$pid_file" ]]; then
    local pid
    pid="$(cat "$pid_file")"
    if kill -0 "$pid" >/dev/null 2>&1; then
      pid_status="running (PID $pid)"
    else
      pid_status="stale pid file"
    fi
  else
    local unmanaged_pid
    unmanaged_pid="$(find_existing_pid "$process_pattern")"
    if [[ -n "$unmanaged_pid" ]]; then
      pid_status="unmanaged (PID $unmanaged_pid)"
    fi
  fi

  if curl --connect-timeout 1 --max-time 2 -fsS "$url" >/dev/null 2>&1; then
    http_status="ready"
  fi

  printf '%-16s %-24s %s
' "$name" "$pid_status" "$http_status"
}

printf '%-16s %-24s %s
' 'Service' 'Process' 'HTTP'
report_service 'Frontend' "$PID_DIR/frontend.pid" "http://127.0.0.1:${FRONTEND_PORT}/" "$ROOT_DIR/frontend/node_modules/.bin/vite --host 0.0.0.0 --port ${FRONTEND_PORT}"
report_service 'Backend' "$PID_DIR/backend.pid" "http://127.0.0.1:${SERVER_PORT}/api/common/ping" "$ROOT_DIR/backend.*spring-boot:run -Dspring-boot.run.profiles="
report_service 'AI service' "$PID_DIR/ai-service.pid" "http://127.0.0.1:${AI_SERVICE_PORT}/health" "python3 -m uvicorn app.main:app --host ${AI_SERVICE_HOST:-0.0.0.0} --port ${AI_SERVICE_PORT}"
