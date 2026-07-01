# CODINGSTYLE

## 1. Java 后端编码风格

### 1.1 包命名

包名使用小写：

```text
com.example.learning.user
com.example.learning.course
com.example.learning.studyroom
```

### 1.2 类命名

```
UserController
UserService
UserServiceImpl
UserMapper
UserEntity
UserLoginDTO
UserProfileVO
```

### 1.3 方法命名

方法使用小驼峰：

```
login()
createCourse()
updateVideoProgress()
joinStudyRoom()
```

### 1.4 常量命名

常量使用大写下划线：

```
MAX_UPLOAD_SIZE
TOKEN_EXPIRE_SECONDS
DEFAULT_PAGE_SIZE
```

### 1.5 Controller 规则

Controller 只负责：

1. 接收请求。
2. 参数校验。
3. 调用 Service。
4. 返回统一响应。

禁止在 Controller 中写复杂业务逻辑。

### 1.6 Service 规则

Service 负责业务逻辑。

复杂业务必须拆分私有方法。

涉及多表写入必须加事务：

```
@Transactional
public void submitExam(...) {
    ...
}
```

### 1.7 DTO / VO / Entity 规则

- DTO：接收请求。
- VO：返回前端。
- Entity：数据库映射。

禁止直接返回 Entity。

------

## 2. 前端编码风格

### 2.1 目录结构

```
src/
├── api/
├── views/
├── components/
├── router/
├── store/
├── utils/
└── types/
```

### 2.2 命名规则

- 页面组件使用 PascalCase。
- 工具函数使用 camelCase。
- API 文件按模块命名。

示例：

```
CourseDetail.vue
StudyRoom.vue
courseApi.ts
studyRoomApi.ts
```

### 2.3 API 调用

所有接口调用必须封装在 `api/` 目录下。

禁止在页面组件中直接写 axios 请求地址。

------

## 3. SQL 风格

### 3.1 表命名

表名使用小写下划线：

```
user
course
study_record
study_room
```

### 3.2 字段命名

字段使用小写下划线：

```
user_id
course_id
created_at
updated_at
```

### 3.3 必备字段

业务表默认包含：

```
id
created_at
updated_at
deleted
```

### 3.4 注释

所有表和关键字段必须写 COMMENT。

------

## 4. 接口风格

### 4.1 URL 风格

```
GET    /api/courses
GET    /api/courses/{id}
POST   /api/teacher/courses
PUT    /api/teacher/courses/{id}
DELETE /api/teacher/courses/{id}
```

### 4.2 响应格式

所有接口返回统一 ApiResponse。

------

## 5. 注释规则

需要写注释的地方：

1. 复杂业务规则。
2. 状态机流转。
3. 权限判断。
4. Redis Key 含义。
5. WebSocket 消息处理。
6. AI 服务降级逻辑。

不需要写废话注释。

------

## 6. 日志规则

使用 Slf4j。

```
log.info("user {} joined study room {}", userId, roomId);
log.warn("invalid video progress report userId={}, resourceId={}", userId, resourceId);
log.error("ai service call failed", e);
```

禁止日志中输出：

1. 密码。
2. Token。
3. 身份证号。
4. 完整隐私数据。