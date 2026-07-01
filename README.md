# Online Learning System

## 项目结构

- `backend/`：Spring Boot 主系统
- `frontend/`：Vue 3 前端
- `ai-service/`：FastAPI AI 微服务
- `docs/`：需求、接口、测试标准
- `deployment/`：统一环境变量、启动脚本与部署说明

## 为什么 `mvn spring-boot:run` 会失败

如果直接运行后端：

```bash
cd backend
/root/autodl-tmp/environment/apache-maven-3.9.6/bin/mvn spring-boot:run
```

但本机 MySQL 没有启动，Spring Boot 会在初始化 JPA 时失败。当前项目默认依赖：

- MySQL
- Redis
- AI 服务

## AutoDL 服务器直接启动

### 1. 准备统一环境变量

```bash
cd /root/autodl-tmp/online-learning-system
cp deployment/server.env.example deployment/server.env
```

按需修改唯一配置文件 `deployment/server.env`，最重要的是：

- `MYSQL_ROOT_PASSWORD`
- `MYSQL_PASSWORD`
- `JWT_SECRET`
- `APP_AI_BASE_URL`

### 2. 首次安装前端与 AI 依赖

```bash
cd /root/autodl-tmp/online-learning-system/frontend
npm install
cd ../ai-service
pip install -r requirements.txt
cd ..
```

### 3. 一键启动整套本地服务

```bash
cd /root/autodl-tmp/online-learning-system
./deployment/start-local-stack.sh
```

这个脚本会按顺序完成：

- MySQL 启动与数据库初始化
- Redis 启动
- AI 服务后台启动
- Spring Boot 后端后台启动
- Vue 前端后台启动
- 前端代理 `/api` 与 `/ws` 连通性校验

### 4. 查看状态与停止

```bash
./deployment/status-local-stack.sh
./deployment/stop-local-stack.sh
```

### 5. 注入演示数据

```bash
./deployment/seed-demo-data.sh
```

这会补充一套可直接登录和演示的账号、课程、资源、考试、自习室、推荐与公告数据。

- 示例账号：`student001 / 123456`
- 详细清单：`deployment/DEMO_DATA.md`

说明：

- `start-ai-local.sh`、`start-backend-local.sh`、`start-frontend-local.sh` 仍然保留，用于单服务调试。
- 这三个单服务脚本会占用当前终端并以前台方式运行，不适合按顺序直接串行执行。
- 前端默认监听 `0.0.0.0`，可以直接从远程浏览器访问。
- 浏览器请求统一走相对路径 `/api`，不会再误连访问者自己机器的 `127.0.0.1:8080`。
- 前端开发服务器会自动把 `/api` 和 `/ws` 代理到 `SERVER_PORT` 指定的后端。

当前仓库里的 AI 服务是本地占位实现，不需要额外的 `API Key`、模型 URL、OpenAI Key` 之类配置；它会直接返回结构化 mock 结果。

## 手动启动命令

如果你不想走一键脚本，也可以手动执行，但要把 AI、后端、前端分别放到不同终端中。

### 后端测试

```bash
cd /root/autodl-tmp/online-learning-system/backend
/root/autodl-tmp/environment/apache-maven-3.9.6/bin/mvn test
```

### 单服务调试：后端启动

```bash
cd /root/autodl-tmp/online-learning-system/backend
set -a
source ../deployment/server.env
set +a
/root/autodl-tmp/environment/apache-maven-3.9.6/bin/mvn spring-boot:run -Dspring-boot.run.profiles=local
```

### 单服务调试：前端启动

```bash
cd /root/autodl-tmp/online-learning-system/frontend
set -a
source ../deployment/server.env
set +a
npm run dev -- --host 0.0.0.0 --port ${FRONTEND_PORT:-5173}
```

### 单服务调试：AI 服务启动

```bash
cd /root/autodl-tmp/online-learning-system/ai-service
pip install -r requirements.txt
set -a
source ../deployment/server.env
set +a
python3 -m uvicorn app.main:app --host ${AI_SERVICE_HOST:-0.0.0.0} --port ${AI_SERVICE_PORT:-8000}
```

## 访问地址

- 前端：`http://服务器IP:5173`
- 后端：`http://服务器IP:8080`
- AI 服务健康检查：`http://服务器IP:8000/health`

## Docker 启动

### 1. 准备统一环境变量

```bash
cd /root/autodl-tmp/online-learning-system
cp deployment/server.env.example deployment/server.env
```

### 2. 启动整套服务

```bash
docker compose --env-file deployment/server.env up --build
```

### 3. 停止服务

```bash
docker compose --env-file deployment/server.env down
```

## 工程约束

- 所有后端 HTTP 接口统一返回 `ApiResponse`。
- Controller 只负责请求编排，不直接访问 Mapper。
- 密码使用哈希存储，不明文落库。
- Token 不写入业务日志。
- 服务器直启和 Docker 部署共用同一套环境变量命名。
