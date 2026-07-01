# module-study-room

## 1. 模块目标

线上自习室模块负责实现多人在线学习监督、虚拟座位、番茄钟、实时状态同步、专注打卡和排行榜。

该模块是系统的核心亮点之一，技术核心是：

```text
WebSocket + Redis + MySQL 最终流水
```

## 2. 核心概念

### 2.1 自习室 StudyRoom

自习室是一个可容纳多个用户在线学习的虚拟空间。

字段包括：

- roomId
- roomName
- capacity
- currentOnlineCount
- openTime
- closeTime
- status

### 2.2 虚拟座位 Seat

用户进入自习室后，系统为其分配座位。

座位状态：

```
EMPTY
OCCUPIED
LOCKED
```

### 2.3 用户状态 UserRoomState

```
FOCUSING       专注中
BREAK          小憩中
AWAY           暂离
DISCONNECTED   异常断线
LEFT           已离开
```

## 3. 状态机

```
ENTER_ROOM -> FOCUSING
FOCUSING -> BREAK
BREAK -> FOCUSING
FOCUSING -> DISCONNECTED
BREAK -> DISCONNECTED
DISCONNECTED -> FOCUSING
DISCONNECTED -> LEFT
FOCUSING -> LEFT
BREAK -> LEFT
```

## 4. Redis 数据设计

```
studyroom:{roomId}:seats
studyroom:{roomId}:online
studyroom:{roomId}:user:{userId}:state
studyroom:{roomId}:user:{userId}:timer
```

## 5. WebSocket 消息类型

```
ROOM_JOIN
ROOM_LEAVE
ROOM_USER_STATE_CHANGE
ROOM_TIMER_START
ROOM_TIMER_PAUSE
ROOM_TIMER_FINISH
ROOM_HEARTBEAT
ROOM_RECONNECT
```

## 6. 业务流程

### 6.1 加入自习室

1. 前端请求加入自习室。
2. 后端校验用户身份。
3. 后端检查房间是否开放。
4. 后端检查房间容量。
5. 后端在 Redis 中分配座位。
6. 后端通过 WebSocket 广播用户加入事件。

### 6.2 开始番茄钟

1. 用户选择专注时长。
2. 前端发送开始番茄钟消息。
3. 后端记录开始时间和预计结束时间。
4. Redis 保存计时状态。
5. 前端本地展示倒计时。
6. 完成后后端生成专注流水。

### 6.3 断线重连

1. WebSocket 断开后，用户状态变为 DISCONNECTED。
2. Redis 设置短 TTL。
3. 用户在 TTL 内重连，则恢复原状态。
4. 超时未重连，则状态转为 LEFT。
5. 系统结算已完成的有效专注时长。

## 7. MySQL 数据表

```
study_room
study_room_seat
room_record
room_checkin
```

## 8. 关键接口

```
GET  /api/study-rooms
POST /api/study-rooms/{roomId}/join
POST /api/study-rooms/{roomId}/leave
GET  /api/study-rooms/{roomId}/snapshot

GET  /api/student/room-records
GET  /api/student/focus-stats
GET  /api/study-rooms/{roomId}/ranking
```

## 9. 一致性原则

1. 当前在线状态以 Redis 为准。
2. 历史专注记录以 MySQL 为准。
3. WebSocket 只负责推送，不作为永久数据源。
4. 用户离开房间时必须释放 Redis 座位。
5. 异常断线通过 TTL 自动清理。

## 10. 异常情况

1. 自习室已满。
2. 用户重复加入。
3. 用户断线。
4. Redis 中座位状态与数据库不一致。
5. 用户非法切换状态。
6. 番茄钟重复完成。