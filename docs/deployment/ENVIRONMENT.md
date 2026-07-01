# ENVIRONMENT

## 1. 基础环境

建议开发环境：

```text
JDK 17
Maven 3.9+
Node.js 20+
pnpm 8+
MySQL 8+
Redis 7+
Python 3.10+
Docker 24+
Docker Compose 2+
```

## 2. 项目目录

```
online-learning-system/
├── backend/
├── frontend/
├── ai-service/
├── sql/
├── docker-compose.yml
└── docs/
```

## 3. MySQL 初始化

### 3.1 创建数据库

```
CREATE DATABASE online_learning DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

### 3.2 导入表结构

```
mysql -u root -p online_learning < sql/schema.sql
```

### 3.3 导入初始化数据

```
mysql -u root -p online_learning < sql/init_data.sql
```

------

## 4. Redis 启动

本地启动：

```
redis-server
```

Docker 启动：

```
docker run -d \
  --name learning-redis \
  -p 6379:6379 \
  redis:7
```

------

## 5. 后端启动

进入后端目录：

```
cd backend
```

配置 `application-dev.yml`：

```
spring:
  datasource:
    url: jdbc:mysql://localhost:3306/online_learning?useUnicode=true&characterEncoding=utf8&serverTimezone=Asia/Shanghai
    username: root
    password: your_password

  data:
    redis:
      host: localhost
      port: 6379

jwt:
  secret: change-me
  expire-seconds: 7200

ai:
  service-url: http://localhost:8000
```

启动：

```
mvn clean install
mvn spring-boot:run
```

后端默认地址：

```
http://localhost:8080
```

------

## 6. 前端启动

进入前端目录：

```
cd frontend
```

安装依赖：

```
pnpm install
```

配置 `.env.development`：

```
VITE_API_BASE_URL=http://localhost:8080
VITE_WS_URL=ws://localhost:8080/ws
```

启动：

```
pnpm dev
```

前端默认地址：

```
http://localhost:5173
```

------

## 7. AI 微服务启动

进入 AI 服务目录：

```
cd ai-service
```

创建虚拟环境：

```
python -m venv .venv
```

激活虚拟环境：

Windows：

```
.venv\Scripts\activate
```

Linux / macOS：

```
source .venv/bin/activate
```

安装依赖：

```
pip install -r requirements.txt
```

启动：

```
uvicorn main:app --host 0.0.0.0 --port 8000
```

AI 服务地址：

```
http://localhost:8000
```

------

## 8. Docker Compose 部署

示例 `docker-compose.yml`：

```
version: "3.9"

services:
  mysql:
    image: mysql:8
    container_name: learning-mysql
    environment:
      MYSQL_ROOT_PASSWORD: root
      MYSQL_DATABASE: online_learning
    ports:
      - "3306:3306"
    volumes:
      - mysql_data:/var/lib/mysql
      - ./sql:/docker-entrypoint-initdb.d
    command:
      --default-authentication-plugin=mysql_native_password

  redis:
    image: redis:7
    container_name: learning-redis
    ports:
      - "6379:6379"

  minio:
    image: minio/minio
    container_name: learning-minio
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: admin
      MINIO_ROOT_PASSWORD: admin123456
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data

volumes:
  mysql_data:
  minio_data:
```

启动：

```
docker compose up -d
```

------

## 9. 开发启动顺序

推荐顺序：

```
1. 启动 MySQL
2. 启动 Redis
3. 启动 MinIO
4. 启动 AI 微服务
5. 启动 Spring Boot 后端
6. 启动前端
```

------

## 10. 常见问题

### 10.1 后端无法连接 MySQL

检查：

1. MySQL 是否启动。
2. 数据库名是否正确。
3. 用户名密码是否正确。
4. 端口是否为 3306。

### 10.2 WebSocket 连接失败

检查：

1. Token 是否携带。
2. 后端 WebSocket 配置是否开启。
3. 前端 ws 地址是否正确。
4. 浏览器控制台是否有跨域错误。

### 10.3 AI 服务调用失败

检查：

1. AI 服务是否启动。
2. `ai.service-url` 是否正确。
3. 请求是否超时。
4. Python 依赖是否安装完整。

### 10.4 Redis 状态异常

检查：

1. Redis 是否启动。
2. Key 是否按规范命名。
3. TTL 是否设置过短。
4. 是否存在重复加入房间逻辑。