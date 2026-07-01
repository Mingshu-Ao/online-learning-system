# module-admin-operation

## 1. 模块目标

管理端模块负责平台用户、课程审核、公告、系统日志和运营数据管理。

## 2. 核心功能

### 2.1 用户管理

- 查询用户。
- 新增用户。
- 禁用用户。
- 重置密码。
- 修改角色。

### 2.2 课程审核

课程审核状态：

```text
PENDING
APPROVED
REJECTED
```

管理员需要填写审核意见。

### 2.3 公告管理

- 发布公告。
- 编辑公告。
- 下线公告。
- 设置可见范围。
- 设置发布时间。

### 2.4 日志审计

日志类型：

```
LOGIN_LOG
OPERATION_LOG
RESOURCE_ACCESS_LOG
ERROR_LOG
```

### 2.5 运营看板

展示：

- 用户总数。
- 日活用户。
- 课程总数。
- 今日学习时长。
- 自习室在线人数。
- AI 调用次数。

## 3. 数据表

```
announcement
login_log
operation_log
resource_access_log
system_error_log
```

## 4. 关键接口

```
GET  /api/admin/dashboard
GET  /api/admin/users
PUT  /api/admin/users/{id}/status

GET  /api/admin/courses/review-list
POST /api/admin/courses/{id}/review

POST /api/admin/announcements
PUT  /api/admin/announcements/{id}
DELETE /api/admin/announcements/{id}

GET  /api/admin/logs/login
GET  /api/admin/logs/operation
GET  /api/admin/logs/errors
```

## 5. 安全规则

1. 所有管理端接口必须具有 Admin 权限。
2. 敏感操作必须记录 operation_log。
3. 管理员不能删除自己的管理员权限。
4. 日志不能暴露用户密码和 Token。