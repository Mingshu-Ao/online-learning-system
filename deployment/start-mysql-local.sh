#!/usr/bin/env bash
set -euo pipefail

if mysqladmin ping >/dev/null 2>&1; then
  echo "MySQL is already running."
  exit 0
fi

if command -v service >/dev/null 2>&1; then
  service mysql start >/dev/null 2>&1 || true
fi

if mysqladmin ping >/dev/null 2>&1; then
  echo "MySQL started with service mysql start."
  exit 0
fi

if command -v mysqld_safe >/dev/null 2>&1; then
  mkdir -p /var/run/mysqld
  mysqld_safe --datadir=/var/lib/mysql >/tmp/online-learning-mysql.log 2>&1 &
fi

for _ in {1..20}; do
  if mysqladmin ping >/dev/null 2>&1; then
    echo "MySQL started successfully."
    exit 0
  fi
  sleep 1
done

echo "Failed to start MySQL. Check /tmp/online-learning-mysql.log or system service status." >&2
exit 1
