#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/deployment/server.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

: "${FRONTEND_PORT:=5173}"
: "${SERVER_PORT:=8080}"
: "${VITE_API_BASE_URL:=/api}"
: "${VITE_WS_BASE_URL:=}"
: "${VITE_DEV_PROXY_TARGET:=http://127.0.0.1:${SERVER_PORT}}"

cd "$ROOT_DIR/frontend"
exec npm run dev -- --host 0.0.0.0 --port "$FRONTEND_PORT"
