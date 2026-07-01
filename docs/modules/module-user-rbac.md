# module-user-rbac

## 1. 模块目标

用户与 RBAC 模块负责系统账号体系、登录认证、角色权限控制、Token 管理和基础用户信息维护。

## 2. 核心角色

1. Student：学员
2. Teacher：教师
3. Admin：管理员


## 3. 核心功能

### 3.1 注册

\- 学生可注册账号。
\- 教师账号可由管理员创建或审核。
\- 用户名、手机号、邮箱需要唯一性校验。
\- 密码必须使用 BCrypt 加密。

### 3.2 登录

\- 用户输入账号密码。
\- 后端校验用户状态。
\- 登录成功后生成 JWT。
\- Redis 可保存用户 Token 或 Token 黑名单。

### 3.3 权限校验

权限分为三层：

1. 菜单权限：控制前端菜单是否展示。
2. 按钮权限：控制页面按钮是否展示。
3. 接口权限：控制后端接口是否允许访问。


后端接口权限是最终安全边界，不能只依赖前端控制。

### 3.4 用户管理

- 查询用户列表。
- 新增用户。
- 禁用用户。
- 重置密码。
- 修改用户角色。

## 4. 数据表

```text
user
role
permission
user_role
role_permission
```

## 5. 关键接口

```
POST /api/auth/register
POST /api/auth/login
POST /api/auth/logout
GET  /api/user/profile
PUT  /api/user/profile
GET  /api/admin/users
POST /api/admin/users
PUT  /api/admin/users/{id}/status
PUT  /api/admin/users/{id}/roles
```

## 6. 业务规则

1. 禁用用户不得登录。
2. 已登录用户被禁用后，下次请求应被拒绝。
3. 管理员不能删除自己的管理员角色。
4. 用户密码不得明文返回前端。
5. Token 过期后必须重新登录。

## 7. 异常情况

1. 用户不存在。
2. 密码错误。
3. 用户被禁用。
4. Token 过期。
5. 权限不足。
6. 重复注册。