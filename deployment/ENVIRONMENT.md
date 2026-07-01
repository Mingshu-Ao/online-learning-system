# Deployment Environment Guide

## 1. 运行依赖

服务器直启模式下，需要准备以下运行时：

- Java 17
- Maven 3.9.6
- Node.js + npm
- Python 3.11+
- MySQL 8+
- Redis 7+

当前这台 AutoDL 机器已经确认存在：

- `mysqld`
- `mysql`
- `node`
- `npm`
- `python3`

当前这台机器未检测到：

- `redis-server`

所以如果要完整运行自习室、限流等 Redis 依赖功能，需要先安装 Redis。

## 2. 统一环境变量文件

- 模板文件：`deployment/server.env.example`
- 实际文件：`deployment/server.env`
- 服务器直启和 Docker Compose 共用这一份配置

## 3. 服务器直启推荐顺序

### 3.1 准备环境变量

```bash
cd /root/autodl-tmp/online-learning-system
cp deployment/server.env.example deployment/server.env
```

### 3.2 安装依赖

首次安装依赖：

```bash
cd frontend
npm install
cd ../ai-service
pip install -r requirements.txt
cd ..
```

### 3.3 一键启动整套服务

```bash
./deployment/start-local-stack.sh
```

这个脚本会自动完成：

- MySQL 启动与数据库初始化
- Redis 启动
- AI 服务后台启动
- Spring Boot 后端后台启动
- Vue 前端后台启动
- 前端代理 `/api` 与 `/ws` 连通性校验

说明：

- 当前仓库中的 AI 服务是本地 FastAPI 占位实现。
- 不需要额外配置 OpenAI API Key、第三方模型 URL、代理地址。
- 后端只需要能访问 `APP_AI_BASE_URL` 指向的服务即可。

### 3.4 查看状态与停止

```bash
./deployment/status-local-stack.sh
./deployment/stop-local-stack.sh
```

### 3.5 单服务调试

```bash
./deployment/start-ai-local.sh
./deployment/start-backend-local.sh
./deployment/start-frontend-local.sh
```

说明：

- 上面三个脚本都会占用当前终端并以前台方式运行。
- 如果你要同时跑它们，需要分别放到不同终端中。
- 前端默认监听 `0.0.0.0`
- 浏览器请求统一走 `/api`
- 开发服务器会把 `/api` 和 `/ws` 代理到 `SERVER_PORT` 指定的后端

## 4. 常见问题

### 4.1 `mvn spring-boot:run` 直接失败

如果看到类似下面的异常：

- `Unable to determine Dialect without JDBC metadata`
- `Failed to execute goal spring-boot:run`

通常不是 Maven 问题，而是后端启动时连不上 MySQL。

先确认：

```bash
mysqladmin ping
```

如果失败，优先执行：

```bash
./deployment/start-mysql-local.sh
./deployment/init-mysql-local.sh
```

### 4.2 Redis 不存在

自习室状态、番茄钟、AI 限流依赖 Redis。没有 Redis 时，系统不能完整运行这部分功能。

### 4.3 AI 服务是否要配置 Key

当前版本不需要。

如果未来把 `ai-service` 改成真实大模型调用服务，再在 `ai-service` 内部增加：

- `OPENAI_API_KEY` 或其他厂商密钥
- 外部模型 `base_url`
- 模型名等推理参数

主系统后端本身不直接需要这些第三方 Key。

## 5. Docker 对齐说明

为了后续脱离 AutoDL 环境仍可使用 Docker：

- 后端配置已显式支持 `DB_*`、`SPRING_DATA_REDIS_*`、`APP_AI_*`
- 前端支持 `VITE_API_BASE_URL`、`VITE_WS_BASE_URL`
- AI 服务支持通过容器环境变量指定监听 Host/Port
- `docker compose --env-file deployment/server.env` 与本地直启脚本使用同一套核心变量命名
