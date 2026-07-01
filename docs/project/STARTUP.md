# 项目启动说明

## 1. 目录说明

```text
online-learning-system/
├── backend/        # Spring Boot 后端骨架
├── frontend/       # Vue 3 + TypeScript 前端骨架
├── ai-service/     # FastAPI AI 微服务骨架
├── sql/            # 数据库初始化脚本
└── docs/           # 设计与启动文档
```

## 2. 统一配置文件

所有启动方式都统一使用同一份环境变量文件：

```bash
cd /root/autodl-tmp/online-learning-system
cp deployment/server.env.example deployment/server.env
```

需要重点确认的变量：

- `MYSQL_ROOT_PASSWORD`
- `MYSQL_PASSWORD`
- `JWT_SECRET`
- `APP_AI_BASE_URL`
- `SERVER_PORT`
- `FRONTEND_PORT`

## 3. 一键启动整套本地服务

要求：

- JDK 17+
- Maven 3.9+
- Node.js 20+
- npm 10+
- Python 3.10+
- MySQL 8+

首次安装依赖：

```bash
cd /root/autodl-tmp/online-learning-system/frontend
npm install
cd ../ai-service
pip install -r requirements.txt
cd ..
```

启动命令：

```bash
cd /root/autodl-tmp/online-learning-system
./deployment/start-local-stack.sh
```

这个脚本会自动完成：

- MySQL 启动
- 数据库初始化
- Redis 启动
- AI 服务后台启动
- Spring Boot 后端后台启动
- Vue 前端后台启动
- 前端到后端代理联通校验

访问地址：

- 前端：`http://服务器IP:5173`
- 后端：`http://服务器IP:8080`
- AI 服务健康检查：`http://服务器IP:8000/health`

查看状态与停止：

```bash
./deployment/status-local-stack.sh
./deployment/stop-local-stack.sh
```

## 4. 运行后端测试

```bash
cd /root/autodl-tmp/online-learning-system/backend
/root/autodl-tmp/environment/apache-maven-3.9.6/bin/mvn test
```

测试使用 `H2` 内存数据库，不依赖生产 MySQL。

## 5. 单服务调试

以下脚本保留给单服务调试使用：

```bash
./deployment/start-ai-local.sh
./deployment/start-backend-local.sh
./deployment/start-frontend-local.sh
```

说明：

- 这三个脚本都会占用当前终端并以前台方式运行。
- 如果你要同时跑它们，需要分别放到不同终端中。
- 正常使用时，优先执行 `./deployment/start-local-stack.sh`。

## 6. 启动 AI 服务

要求：

- Python 3.10+

命令：

```bash
cd /root/autodl-tmp/online-learning-system/ai-service
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
set -a
source ../deployment/server.env
set +a
uvicorn app.main:app --host ${AI_SERVICE_HOST:-0.0.0.0} --port ${AI_SERVICE_PORT:-8000}
```

默认端口：`8000`

接口：

- `GET /health`
- `POST /api/v1/solve-question`

## 7. Docker Compose 部署

同样使用 `deployment/server.env`：

```bash
cd /root/autodl-tmp/online-learning-system
docker compose --env-file deployment/server.env up --build
```
