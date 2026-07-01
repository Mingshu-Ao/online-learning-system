#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/deployment/server.env"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

: "${AI_SERVICE_HOST:=0.0.0.0}"
: "${AI_SERVICE_PORT:=8000}"

cd "$ROOT_DIR/ai-service"
exec python3 -m uvicorn app.main:app --host "$AI_SERVICE_HOST" --port "$AI_SERVICE_PORT"
