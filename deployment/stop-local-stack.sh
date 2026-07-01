#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
PID_DIR="$ROOT_DIR/.local-run/pids"

stop_pid_file() {
  local name="$1"
  local pid_file="$2"
  if [[ ! -f "$pid_file" ]]; then
    echo "$name is not managed by $pid_file"
    return 0
  fi

  local pid
  pid="$(cat "$pid_file")"
  if kill -0 "$pid" >/dev/null 2>&1; then
    echo "Stopping $name (PID $pid) ..."
    kill "$pid"
    for _ in {1..20}; do
      if ! kill -0 "$pid" >/dev/null 2>&1; then
        rm -f "$pid_file"
        echo "$name stopped."
        return 0
      fi
      sleep 1
    done
    echo "$name did not stop gracefully, sending SIGKILL ..."
    kill -9 "$pid" >/dev/null 2>&1 || true
  else
    echo "$name PID file exists but process is not running."
  fi
  rm -f "$pid_file"
}

stop_pid_file "Frontend" "$PID_DIR/frontend.pid"
stop_pid_file "Backend" "$PID_DIR/backend.pid"
stop_pid_file "AI service" "$PID_DIR/ai-service.pid"

echo "Application services stopped. MySQL and Redis were left running."
