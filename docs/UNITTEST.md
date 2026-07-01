# UNITTEST

## 1. 单元测试目标

单元测试用于验证 Service 层、工具类、权限逻辑、状态机和核心业务规则的正确性。

## 2. 测试框架

后端：

- JUnit 5
- Mockito
- Spring Boot Test

前端：

- Vitest / Jest
- Vue Test Utils / React Testing Library

AI 微服务：

- pytest

## 3. 后端单元测试范围

### 3.1 用户模块

测试内容：

1. 密码加密是否正确。
2. 登录成功是否生成 Token。
3. 禁用用户是否不能登录。
4. 权限判断是否正确。

### 3.2 课程模块

测试内容：

1. 教师是否能创建课程。
2. 非课程作者是否不能修改课程。
3. 课程状态流转是否正确。
4. 未上架课程是否不能被学生访问。

### 3.3 学习进度模块

测试内容：

1. 正常进度上报。
2. 异常跳跃进度识别。
3. 倍速播放进度计算。
4. 课程完成度计算。

### 3.4 测验模块

测试内容：

1. 单选题判分。
2. 多选题判分。
3. 判断题判分。
4. 错题自动收录。
5. 重复提交处理。

### 3.5 自习室模块

测试内容：

1. 加入房间。
2. 房间满员。
3. 座位分配。
4. 状态机流转。
5. 番茄钟完成结算。
6. 断线重连。

### 3.6 AI 模块

测试内容：

1. AI 服务调用成功。
2. AI 服务超时。
3. AI 返回格式非法。
4. 调用日志保存。
5. 限流逻辑。

---

## 4. 单元测试命名规范

测试类命名：

```text
UserServiceTest
CourseServiceTest
StudyRoomServiceTest
```

测试方法命名：

```
shouldLoginSuccessfullyWhenPasswordIsCorrect()
shouldRejectLoginWhenUserDisabled()
shouldRejectJoinRoomWhenRoomIsFull()
shouldCreateWrongQuestionWhenAnswerIncorrect()
```

------

## 5. 测试数据要求

1. 测试数据必须独立。
2. 测试之间不能相互依赖。
3. 不得依赖生产数据库。
4. Redis 测试可使用 Mock 或测试容器。
5. AI 服务测试优先使用 Mock。

------

## 6. 覆盖率要求

1. Service 层核心业务覆盖率不低于 80%。
2. 权限相关逻辑覆盖率不低于 90%。
3. 自习室状态机覆盖率不低于 90%。
4. 判分逻辑覆盖率不低于 90%。
5. 工具类覆盖率不低于 80%。

------

## 7. 必测边界

1. 空参数。
2. 非法状态。
3. 权限不足。
4. 重复提交。
5. 并发冲突。
6. 外部服务不可用。
7. 数据不存在。