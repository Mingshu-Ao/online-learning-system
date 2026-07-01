#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
ENV_FILE="$ROOT_DIR/deployment/server.env"

# 加载环境变量
if [[ -f "$ENV_FILE" ]]; then
  set -a
  source "$ENV_FILE"
  set +a
else
  echo "警告: 未找到 $ENV_FILE，将使用默认配置"
fi

# 设置默认值
: "${MYSQL_ROOT_USER:=root}"
: "${MYSQL_ROOT_PASSWORD:=}"
: "${MYSQL_DATABASE:=online_learning_system}"
: "${MYSQL_USER:=online_learning}"
: "${MYSQL_PASSWORD:=change_me_app_password}"

# 构建 MySQL 登录命令
MYSQL_CMD=(mysql -u"$MYSQL_ROOT_USER")
if [[ -n "$MYSQL_ROOT_PASSWORD" ]]; then
  MYSQL_CMD+=(-p"$MYSQL_ROOT_PASSWORD")
fi

echo "正在初始化数据库: $MYSQL_DATABASE ..."

# 执行 SQL (注意下面反斜杠加反引号的正确写法)
"${MYSQL_CMD[@]}" <<SQL
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${MYSQL_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'127.0.0.1' IDENTIFIED BY '${MYSQL_PASSWORD}';

GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'127.0.0.1';

FLUSH PRIVILEGES;
SQL

echo "MySQL database and user are ready."