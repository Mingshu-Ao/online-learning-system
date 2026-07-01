# Interface

## 1. 接口规范

所有接口统一使用 JSON 格式。

### 1.1 成功响应

```json
{
  "code": 0,
  "message": "success",
  "data": {}
}
```

### 1.2 失败响应

```
{
  "code": 40000,
  "message": "参数错误",
  "data": null
}
```

------

## 2. 认证接口

### 2.1 登录

```
POST /api/auth/login
```

请求：

```
{
  "username": "student001",
  "password": "123456"
}
```

响应：

```
{
  "code": 0,
  "message": "success",
  "data": {
    "token": "jwt-token",
    "userId": 1,
    "username": "student001",
    "roles": ["Student"]
  }
}
```

------

## 3. 课程接口

### 3.1 查询课程列表

```
GET /api/courses?page=1&pageSize=10&keyword=java
```

响应：

```
{
  "code": 0,
  "message": "success",
  "data": {
    "total": 100,
    "records": [
      {
        "id": 1,
        "title": "Java 程序设计",
        "coverUrl": "https://example.com/cover.jpg",
        "teacherName": "张老师",
        "difficulty": "BEGINNER",
        "studentCount": 200
      }
    ]
  }
}
```

### 3.2 查询课程详情

```
GET /api/courses/{courseId}
```

### 3.3 查询章节

```
GET /api/courses/{courseId}/chapters
```

------

## 4. 学习进度接口

### 4.1 上报视频进度

```
POST /api/student/video-progress
```

请求：

```
{
  "courseId": 1,
  "chapterId": 10,
  "resourceId": 100,
  "currentPosition": 320,
  "duration": 1200,
  "playbackRate": 1.25,
  "clientTimestamp": 1710000000000
}
```

响应：

```
{
  "code": 0,
  "message": "success",
  "data": {
    "progressPercent": 26.7,
    "completed": false
  }
}
```

------

## 5. 测验接口

### 5.1 开始考试

```
POST /api/student/exams/{paperId}/start
```

响应：

```
{
  "code": 0,
  "message": "success",
  "data": {
    "examRecordId": 10001,
    "paperId": 1,
    "startTime": "2026-03-24 10:00:00",
    "endTime": "2026-03-24 11:00:00"
  }
}
```

### 5.2 提交答案

```
POST /api/student/exams/{examRecordId}/submit
```

请求：

```
{
  "answers": [
    {
      "questionId": 1,
      "answer": "A"
    },
    {
      "questionId": 2,
      "answer": ["A", "C"]
    }
  ]
}
```

------

## 6. 自习室接口

### 6.1 查询自习室列表

```
GET /api/study-rooms
```

### 6.2 加入自习室

```
POST /api/study-rooms/{roomId}/join
```

响应：

```
{
  "code": 0,
  "message": "success",
  "data": {
    "roomId": 1,
    "seatNo": 8,
    "state": "FOCUSING"
  }
}
```

### 6.3 获取房间快照

```
GET /api/study-rooms/{roomId}/snapshot
```

响应：

```
{
  "code": 0,
  "message": "success",
  "data": {
    "roomId": 1,
    "onlineCount": 20,
    "seats": [
      {
        "seatNo": 1,
        "userId": 1001,
        "nickname": "Alice",
        "state": "FOCUSING"
      }
    ]
  }
}
```

------

## 7. WebSocket 协议

### 7.1 连接地址

```
/ws?token={jwt-token}
```

### 7.2 消息格式

```
{
  "type": "ROOM_USER_STATE_CHANGE",
  "roomId": 1,
  "senderId": 1001,
  "timestamp": 1710000000000,
  "payload": {
    "state": "BREAK"
  }
}
```

### 7.3 常见消息类型

```
ROOM_JOIN
ROOM_LEAVE
ROOM_USER_STATE_CHANGE
ROOM_TIMER_START
ROOM_TIMER_FINISH
ROOM_HEARTBEAT
ROOM_RECONNECT
```

------

## 8. AI 接口

### 8.1 文本提问

```
POST /api/student/ai/ask
```

请求：

```
{
  "courseId": 1,
  "question": "递归和迭代有什么区别？"
}
```

### 8.2 图片错题解析

```
POST /api/student/ai/solve-image
Content-Type: multipart/form-data
```

字段：

```
courseId
image
```

响应：

```
{
  "code": 0,
  "message": "success",
  "data": {
    "questionText": "识别出的题目文本",
    "knowledgePoints": ["递归"],
    "solutionSteps": ["步骤1", "步骤2"],
    "recommendations": []
  }
}
```