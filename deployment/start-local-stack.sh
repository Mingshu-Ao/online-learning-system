#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/deployment/server.env"
LOG_DIR="$ROOT_DIR/.local-run/logs"
PID_DIR="$ROOT_DIR/.local-run/pids"
MAVEN_BIN="/root/autodl-tmp/environment/apache-maven-3.9.6/bin/mvn"

mkdir -p "$LOG_DIR" "$PID_DIR"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

: "${SPRING_PROFILES_ACTIVE:=local}"
: "${AI_SERVICE_HOST:=0.0.0.0}"
: "${AI_SERVICE_PORT:=8000}"
: "${SERVER_PORT:=8080}"
: "${FRONTEND_PORT:=5173}"
: "${VITE_API_BASE_URL:=/api}"
: "${VITE_WS_BASE_URL:=}"
: "${VITE_DEV_PROXY_TARGET:=http://127.0.0.1:${SERVER_PORT}}"

curl_ready() {
  local url="$1"
  curl --connect-timeout 1 --max-time 2 -fsS "$url" >/dev/null 2>&1
}

wait_for_http() {
  local url="$1"
  local name="$2"
  local attempts="${3:-60}"
  echo "Waiting for $name readiness: $url"
  for ((i = 1; i <= attempts; i++)); do
    if curl_ready "$url"; then
      echo "$name is ready: $url"
      return 0
    fi
    if (( i % 5 == 0 )); then
      echo "Still waiting for $name ... (${i}s)"
    fi
    sleep 1
  done
  echo "$name did not become ready in time: $url" >&2
  return 1
}

is_pid_running() {
  local pid="$1"
  [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1
}

find_existing_pid() {
  local pattern="$1"
  pgrep -f "$pattern" | head -n 1 || true
}

start_managed_service() {
  local name="$1"
  local pid_file="$2"
  local log_file="$3"
  local ready_url="$4"
  local process_pattern="$5"
  shift 5

  if [[ -f "$pid_file" ]]; then
    local existing_pid
    existing_pid="$(cat "$pid_file")"
    if is_pid_running "$existing_pid"; then
      echo "$name is already running with PID $existing_pid"
      wait_for_http "$ready_url" "$name"
      return 0
    fi
    rm -f "$pid_file"
  fi

  echo "Checking whether $name is already reachable ..."
  if curl_ready "$ready_url"; then
    local adopted_pid
    adopted_pid="$(find_existing_pid "$process_pattern")"
    if [[ -n "$adopted_pid" ]]; then
      echo "$name is already reachable and matches PID $adopted_pid. Adopting it into $pid_file."
      echo "$adopted_pid" > "$pid_file"
      wait_for_http "$ready_url" "$name"
      return 0
    fi
    echo "$name is already reachable at $ready_url but is not managed by this script."
    echo "Run ./deployment/clean-local-stack.sh if you want a clean restart."
    wait_for_http "$ready_url" "$name"
    return 0
  fi

  echo "Starting $name ..."
  if command -v setsid >/dev/null 2>&1; then
    setsid "$@" >"$log_file" 2>&1 < /dev/null &
  else
    nohup "$@" >"$log_file" 2>&1 < /dev/null &
  fi
  local pid=$!
  echo "$pid" >"$pid_file"

  if ! wait_for_http "$ready_url" "$name"; then
    echo "$name failed to start. Recent log output:" >&2
    tail -n 80 "$log_file" >&2 || true
    return 1
  fi
}

echo "Preparing local dependencies ..."
"$ROOT_DIR/deployment/start-mysql-local.sh"
"$ROOT_DIR/deployment/init-mysql-local.sh"
"$ROOT_DIR/deployment/start-redis-local.sh"

start_managed_service   "AI service"   "$PID_DIR/ai-service.pid"   "$LOG_DIR/ai-service.log"   "http://127.0.0.1:${AI_SERVICE_PORT}/health"   "python3 -m uvicorn app.main:app --host ${AI_SERVICE_HOST} --port ${AI_SERVICE_PORT}"   bash -lc "cd '$ROOT_DIR/ai-service' && exec python3 -m uvicorn app.main:app --host '$AI_SERVICE_HOST' --port '$AI_SERVICE_PORT'"

start_managed_service   "Backend"   "$PID_DIR/backend.pid"   "$LOG_DIR/backend.log"   "http://127.0.0.1:${SERVER_PORT}/api/common/ping"   "$ROOT_DIR/backend.*spring-boot:run -Dspring-boot.run.profiles=${SPRING_PROFILES_ACTIVE}"   bash -lc "cd '$ROOT_DIR/backend' && exec '$MAVEN_BIN' spring-boot:run -Dspring-boot.run.profiles='$SPRING_PROFILES_ACTIVE'"

start_managed_service   "Frontend"   "$PID_DIR/frontend.pid"   "$LOG_DIR/frontend.log"   "http://127.0.0.1:${FRONTEND_PORT}/"   "$ROOT_DIR/frontend/node_modules/.bin/vite --host 0.0.0.0 --port ${FRONTEND_PORT}"   bash -lc "cd '$ROOT_DIR/frontend' && exec npm run dev -- --host 0.0.0.0 --port '$FRONTEND_PORT'"

wait_for_http "http://127.0.0.1:${FRONTEND_PORT}/api/common/ping" "Frontend proxy"

echo
echo "Local stack is ready."
echo "Frontend: http://127.0.0.1:${FRONTEND_PORT}"
echo "Backend:  http://127.0.0.1:${SERVER_PORT}"
echo "AI:       http://127.0.0.1:${AI_SERVICE_PORT}/health"
echo "Logs:     $LOG_DIR"
echo "PIDs:     $PID_DIR"
