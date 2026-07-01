#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/deployment/server.env"
MAVEN_BIN="/root/autodl-tmp/environment/apache-maven-3.9.6/bin/mvn"

if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
fi

: "${SPRING_PROFILES_ACTIVE:=local}"

cd "$ROOT_DIR/backend"
exec "$MAVEN_BIN" spring-boot:run -Dspring-boot.run.profiles="$SPRING_PROFILES_ACTIVE"
