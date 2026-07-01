# module-course-learning

## 1. 模块目标

课程学习模块负责课程、章节、资源、视频播放、学习进度和课程完成度计算，是在线学习系统的核心主流程。

## 2. 核心功能

### 2.1 课程管理

教师可以创建、编辑、提交审核课程。管理员审核通过后，课程才能上架。

课程状态：

```text
DRAFT       草稿
PENDING     待审核
PUBLISHED   已上架
REJECTED    审核驳回
OFFLINE     已下架
```

### 2.2 章节管理

- 支持多级章节。
- 支持章节排序。
- 每个章节可绑定多个资源。
- 每个章节可绑定章节测验。

### 2.3 资源管理

资源类型：

```
VIDEO
PDF
PPT
IMAGE
LINK
```

视频资源需要记录：

- 文件地址
- 视频时长
- 文件大小
- 转码状态
- 封面
- 所属章节

### 2.4 学习进度

系统记录：

- 当前播放位置。
- 累计有效观看时长。
- 最近学习时间。
- 是否完成。
- 完成百分比。

### 2.5 防进度篡改

前端上报播放进度时，后端需要校验：

1. 本次上报时间与上次上报时间间隔是否合理。
2. 播放进度增长是否超过合理范围。
3. 是否存在短时间内跳跃式完成。
4. 倍速播放是否在允许范围内。

## 3. 数据表

```
course
course_chapter
course_resource
course_enrollment
video_progress
study_record
learning_daily_stat
certificate
```

## 4. 关键接口

```
GET  /api/courses
GET  /api/courses/{id}
POST /api/teacher/courses
PUT  /api/teacher/courses/{id}
POST /api/teacher/courses/{id}/submit-review
POST /api/admin/courses/{id}/review

GET  /api/courses/{courseId}/chapters
POST /api/teacher/courses/{courseId}/chapters
PUT  /api/teacher/chapters/{chapterId}

POST /api/teacher/resources/upload
GET  /api/resources/{resourceId}/access-url

POST /api/student/video-progress
GET  /api/student/courses/{courseId}/progress
GET  /api/student/learning-stats
```

## 5. 课程完成规则

默认课程完成条件：

1. 视频学习完成率 >= 90%。
2. 必修章节测验全部完成。
3. 课程最终测验达到及格线。

课程完成后生成证书。

## 6. 异常情况

1. 课程不存在。
2. 课程未上架。
3. 用户未报名课程。
4. 用户无权访问资源。
5. 视频进度上报异常。
6. 文件资源不存在。