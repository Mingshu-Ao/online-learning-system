# module-quiz-exam

## 1. 模块目标

测验模块负责题库、试卷、答题、判分、成绩记录和错题本，是学习效果评价的核心模块。

## 2. 题型

系统支持以下题型：

```text
SINGLE_CHOICE     单选题
MULTIPLE_CHOICE   多选题
TRUE_FALSE        判断题
FILL_BLANK        填空题
SHORT_ANSWER      简答题
```

## 3. 题库功能

每道题需要包含：

- 题干
- 题型
- 选项
- 标准答案
- 解析
- 难度
- 所属课程
- 所属章节
- 关联知识点

## 4. 试卷功能

试卷包含：

- 试卷标题
- 所属课程
- 题目列表
- 总分
- 及格线
- 考试时长
- 是否允许重做
- 生效时间
- 截止时间

## 5. 判分规则

### 5.1 客观题

客观题自动判分。

- 单选题完全一致得分。
- 多选题可配置完全正确得分或部分得分。
- 判断题完全一致得分。
- 填空题支持标准答案匹配。

### 5.2 主观题

主观题支持教师批改。

AI 可提供评分建议，但最终分数由教师确认。

## 6. 错题本规则

答错的题自动进入错题本。

错题状态：

```
UNMASTERED   未掌握
REVIEWING    复习中
MASTERED     已掌握
```

## 7. 数据表

```
question
question_option
paper
paper_question
exam_record
user_answer
wrong_question
```

## 8. 关键接口

```
POST /api/teacher/questions
PUT  /api/teacher/questions/{id}
GET  /api/teacher/questions

POST /api/teacher/papers
PUT  /api/teacher/papers/{id}
GET  /api/student/papers/{paperId}

POST /api/student/exams/{paperId}/start
POST /api/student/exams/{examRecordId}/submit
GET  /api/student/exams/{examRecordId}/result

GET  /api/student/wrong-questions
POST /api/student/wrong-questions/{id}/redo
PUT  /api/student/wrong-questions/{id}/mastered
```

## 9. 异常情况

1. 试卷不存在。
2. 考试已过期。
3. 用户重复提交。
4. 用户无权限参加考试。
5. 主观题未批改。
6. 题目答案格式非法。