# OUTLINE

## 项目名称

在线学习系统 Online Learning System

## 项目目标

本项目旨在实现一个集课程学习、视频播放、测验考试、错题管理、线上自习室、AI 智能助教、知识图谱学习路径推荐、教师学情监控和后台运营管理于一体的在线学习平台。

## 核心用户角色

1. 学员 Student
2. 教师 Teacher
3. 管理员 Admin

## 核心技术栈

- 后端：Spring Boot
- 权限认证：Spring Security + JWT
- 数据库：MySQL
- 缓存与实时状态：Redis
- 实时通信：WebSocket
- 前端：Vue.js 或 React
- AI 微服务：Python + FastAPI + PyTorch
- 文件存储：本地 MinIO 或对象存储
- 部署：Docker / Docker Compose

## 核心代码位置

- 后端主系统：`backend/`
- 前端系统：`frontend/`
- AI 微服务：`ai-service/`
- 数据库脚本：`sql/`
- 接口文档：`docs/Interface.md`
- 模块设计：`docs/modules/`
- 测试用例：`tests/`

## 核心业务模块

1. 用户与 RBAC 权限模块
2. 课程与章节模块
3. 视频资源与学习进度模块
4. 题库、试卷与测验模块
5. 错题本模块
6. 线上自习室模块
7. AI 智能助教模块
8. 知识图谱学习路径模块
9. 教师学情分析模块
10. 管理端运营与日志审计模块

## 代码风格

后端遵循 Java 分层架构：

- controller
- service
- service.impl
- mapper / repository
- entity
- dto
- vo
- config
- security
- websocket
- common

前端遵循组件化开发：

- api
- views
- components
- router
- store
- utils

## 核心约束

1. 所有接口默认需要鉴权，除登录、注册、公开课程列表外。
2. 所有敏感数据不得明文存储。
3. 学习进度不得完全信任前端上报。
4. 自习室实时状态以 Redis 为准，MySQL 只保存最终流水。
5. WebSocket 断线后必须支持状态恢复。
6. AI 微服务不得直接访问主业务数据库。
7. 管理端敏感操作必须写入审计日志。
8. 课程资源访问必须进行权限校验。
9. 不允许在 Controller 中编写复杂业务逻辑。
10. 不允许绕过 Service 层直接操作数据库。

## 绝对不能碰的红线

1. 不允许明文保存密码。
2. 不允许未鉴权访问付费或受限课程资源。
3. 不允许前端自行决定课程完成状态。
4. 不允许 WebSocket 消息未经身份校验直接广播。
5. 不允许 AI 服务返回内容直接写入核心业务表而不经主系统校验。
6. 不允许删除正式学习记录，最多只能做逻辑删除或审计修正。