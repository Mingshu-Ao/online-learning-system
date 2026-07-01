# CONVENTIONS.md

## 1. 总体约定

本项目采用前后端分离架构，后端负责业务逻辑、权限校验、数据持久化和实时通信，前端负责页面展示、用户交互和状态管理，AI 微服务负责模型推理和智能分析。

## 2. 分层约定

后端必须遵循以下分层：

```text
controller -> service -> mapper/repository -> database
```

禁止：

- Controller 直接访问 Mapper。
- Controller 中编写复杂业务逻辑。
- Service 返回 Entity 给前端。
- 前端直接拼接数据库字段含义。

## 3. 数据传输约定

- 请求参数使用 DTO。
- 返回前端使用 VO。
- 数据库实体使用 Entity。
- 分页请求统一使用 PageRequestDTO。
- 分页返回统一使用 PageResultVO。

## 4. 接口响应格式

所有 HTTP 接口统一返回：

```
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

约定：

- `code = 0` 表示成功。
- `code != 0` 表示失败。
- `message` 给出用户可理解的错误信息。
- `data` 返回业务数据。

## 5. 错误码约定

```
0       success
40000   bad request
40100   unauthorized
40300   forbidden
40400   not found
40900   conflict
50000   internal server error

10001   user not found
10002   password error
10003   user disabled

20001   course not found
20002   course not published
20003   no course access permission

30001   question not found
30002   paper not found
30003   exam expired

40001   study room full
40002   user already in room
40003   invalid room status

50001   ai service unavailable
50002   ai response timeout
```

## 6. 权限约定

- 默认接口全部需要登录。
- `/api/auth/login`、`/api/auth/register`、公开课程查询接口除外。
- 管理端接口以 `/api/admin/**` 开头。
- 教师端接口以 `/api/teacher/**` 开头。
- 学员端接口以 `/api/student/**` 开头。
- 通用接口以 `/api/common/**` 开头。

## 7. Redis Key 约定

Redis Key 必须统一命名：

```
studyroom:{roomId}:seats
studyroom:{roomId}:online
studyroom:{roomId}:user:{userId}:state
studyroom:{roomId}:user:{userId}:timer
studyroom:{roomId}:messages
user:{userId}:token
course:{courseId}:stats
```

## 8. WebSocket 消息约定

WebSocket 消息必须包含：

```
{
  "type": "ROOM_USER_STATE_CHANGE",
  "roomId": 1,
  "senderId": 1001,
  "timestamp": 1710000000000,
  "payload": {}
}
```

禁止发送无类型、无用户、无时间戳的消息。

## 9. 数据库约定

- 表名使用小写下划线风格。
- 主键统一使用 `id BIGINT`。
- 创建时间字段为 `created_at`。
- 更新时间字段为 `updated_at`。
- 逻辑删除字段为 `deleted`。
- 状态字段使用明确枚举含义。
- 所有关键字段必须有 COMMENT。

## 10. 文件上传约定

- 文件上传必须鉴权。
- 文件大小必须限制。
- 文件类型必须白名单校验。
- 文件访问不得直接暴露真实服务器路径。
- 视频资源建议使用对象存储或 MinIO。

## 11. AI 服务约定

- AI 微服务只通过 HTTP API 与主系统通信。
- AI 微服务不得直接访问主系统数据库。
- AI 返回结果必须经过主系统保存和审计。
- AI 服务异常不得影响核心学习流程。

## 12. 禁止事项

1. 禁止明文保存密码。
2. 禁止绕过权限校验访问资源。
3. 禁止前端直接决定课程完成状态。
4. 禁止将 Redis 作为唯一永久数据源。
5. 禁止在 WebSocket 中广播敏感信息。
6. 禁止在日志中输出密码、Token、身份证号等敏感信息。