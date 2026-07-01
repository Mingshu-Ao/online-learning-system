# ARCHITECTURE

## 1. 总体架构

系统采用前后端分离 + 主业务后端 + AI 微服务的架构。

```text
用户浏览器 / APP
        |
        v
前端 Vue/React
        |
        | HTTP REST API
        | WebSocket
        v
Spring Boot 主业务后端
        |
        |---------------- MySQL：核心业务数据
        |---------------- Redis：缓存、实时状态、自习室状态
        |---------------- MinIO：课程资源、视频、文档
        |
        | HTTP API
        v
Python FastAPI AI 微服务
        |
        | PyTorch / OCR / LLM / 推荐算法
        v
模型推理层
```

## 2. 技术栈

### 2.1 后端

- Spring Boot
- Spring Security
- JWT
- MyBatis Plus 或 Spring Data JPA
- MySQL
- Redis
- WebSocket
- Knife4j / Swagger
- Maven

### 2.2 前端

- Vue 3 或 React
- TypeScript
- Pinia / Redux
- Axios
- WebSocket Client
- ECharts
- Element Plus / Ant Design

### 2.3 AI 微服务

- Python
- FastAPI
- PyTorch
- OCR 组件
- 向量检索组件
- Docker

### 2.4 部署

- Docker
- Docker Compose
- Nginx
- MySQL 8
- Redis 7
- MinIO

------

## 3. 后端模块划分

```
backend/
├── common/             # 通用返回、异常、工具类
├── config/             # 配置类
├── security/           # JWT、权限认证
├── user/               # 用户与权限
├── course/             # 课程与章节
├── resource/           # 文件与视频资源
├── learning/           # 学习进度
├── quiz/               # 题库与考试
├── wrongbook/          # 错题本
├── studyroom/          # 线上自习室
├── ai/                 # AI 调用代理
├── knowledge/          # 知识图谱与推荐
├── admin/              # 管理端
├── websocket/          # WebSocket 消息处理
└── audit/              # 日志审计
```

------

## 4. 数据库核心表

### 4.1 用户与权限

```
user
role
permission
user_role
role_permission
login_log
operation_log
```

### 4.2 课程与资源

```
course
course_chapter
course_resource
course_enrollment
course_review_record
```

### 4.3 学习行为

```
study_record
video_progress
learning_daily_stat
certificate
```

### 4.4 测验与错题

```
question
question_option
paper
paper_question
exam_record
user_answer
wrong_question
```

### 4.5 自习室

```
study_room
study_room_seat
room_record
room_checkin
```

### 4.6 AI 与知识图谱

```
ai_conversation
ai_message
ai_call_log
knowledge_point
knowledge_relation
knowledge_resource
learning_recommendation
```

------

## 5. Redis 设计

Redis 用于处理高频、短生命周期、可恢复的数据。

### 5.1 自习室状态

```
studyroom:{roomId}:seats
studyroom:{roomId}:online
studyroom:{roomId}:user:{userId}:state
studyroom:{roomId}:user:{userId}:timer
```

### 5.2 Token 与权限缓存

```
user:{userId}:token
user:{userId}:permissions
```

### 5.3 课程统计缓存

```
course:{courseId}:stats
course:{courseId}:hot
```

------

## 6. WebSocket 架构

### 6.1 连接建立

1. 前端携带 JWT Token 建立 WebSocket 连接。
2. 后端校验 Token。
3. 校验通过后绑定 userId 和 sessionId。
4. 用户进入自习室后订阅对应 roomId 频道。

### 6.2 消息类型

```
ROOM_JOIN
ROOM_LEAVE
ROOM_USER_STATE_CHANGE
ROOM_TIMER_START
ROOM_TIMER_PAUSE
ROOM_TIMER_FINISH
ROOM_CHAT_MESSAGE
ROOM_HEARTBEAT
ROOM_RECONNECT
```

### 6.3 数据流

```
用户操作
  -> 前端发送 WebSocket 消息
  -> 后端校验身份和房间权限
  -> 更新 Redis 中的房间状态
  -> 广播给同房间用户
  -> 必要时写入 MySQL 流水
```

------

## 7. AI 微服务架构

AI 微服务只负责推理，不负责业务权限。

```
Spring Boot 主系统
    |
    | POST /ai/solve-question
    v
FastAPI AI Service
    |
    | OCR
    | 图像理解
    | 文本理解
    | 知识点提取
    | 解题生成
    v
返回结构化结果
```

AI 返回格式：

```
{
  "question_text": "...",
  "knowledge_points": ["递归", "二叉树"],
  "solution_steps": ["步骤1", "步骤2"],
  "recommendations": [
    {
      "type": "video",
      "resource_id": 1,
      "reason": "该视频讲解递归基础"
    }
  ]
}
```

------

## 8. 学习路径推荐架构

学习路径推荐基于知识图谱：

```
用户错题
  -> 映射知识点
  -> 统计薄弱知识点
  -> 回溯前置知识点
  -> 匹配课程资源
  -> 生成推荐路径
```

推荐结果需要可解释：

```
你在“二叉树遍历”相关题目中错误率较高。
该知识点依赖“递归”和“栈”。
建议先复习“递归基础”，再学习“树的遍历”。
```

------

## 9. 安全架构

1. JWT 登录认证。
2. RBAC 权限控制。
3. 资源访问鉴权。
4. WebSocket 握手鉴权。
5. 文件上传白名单。
6. BCrypt 密码加密。
7. 操作日志审计。
8. 管理端接口权限拦截。
9. AI 调用频率限制。
10. 防止越权访问课程、试卷、学习记录。

------

## 10. 高可用与降级

1. Redis 异常时，自习室功能降级，课程学习不受影响。
2. AI 服务异常时，返回“AI 助教暂不可用”，不影响答题和看课。
3. 文件服务异常时，提示资源加载失败。
4. WebSocket 断开后前端自动重连。
5. 重连后根据 Redis 状态恢复自习室座位和番茄钟。