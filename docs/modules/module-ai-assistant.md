# module-ai-assistant

## 1. 模块目标

AI 智能助教模块负责处理文本答疑、错题截图解析、知识点识别、解题思路生成和学习资源推荐。

AI 模块采用独立微服务部署，主系统通过 HTTP API 调用。

## 2. 架构原则

1. AI 微服务不直接访问主业务数据库。
2. 主系统负责鉴权、限流、记录调用日志。
3. AI 服务只负责推理和生成结构化结果。
4. AI 返回结果不得直接修改用户学习记录。
5. AI 服务失败不影响课程学习、测验、自习室等核心功能。


## 3. 输入类型

```text
TEXT        文本问题
IMAGE       题目截图
HANDWRITING 手写草稿
MIXED       图文混合
```

## 4. 核心能力

### 4.1 文本答疑

输入学生问题，返回：

- 问题解释
- 解题思路
- 关键知识点
- 推荐复习资源

### 4.2 图像错题解析

输入图片后执行：

1. OCR 识别。
2. 公式/手写内容解析。
3. 题目结构提取。
4. 调用大模型生成解题步骤。
5. 返回知识点标签。

### 4.3 错因分析

基于用户错题历史，生成：

- 高频错误知识点。
- 典型错误类型。
- 推荐复习路径。
- 推荐练习题。

## 5. AI 返回格式

```
{
  "question_text": "识别出的题目文本",
  "knowledge_points": ["递归", "二叉树"],
  "difficulty": "MEDIUM",
  "solution_steps": [
    "第一步：分析题目条件",
    "第二步：确定使用递归方法",
    "第三步：写出递归边界"
  ],
  "mistake_analysis": "该题错误原因可能是没有理解递归终止条件。",
  "recommendations": [
    {
      "type": "VIDEO",
      "resource_id": 1001,
      "reason": "该视频讲解递归基础"
    }
  ]
}
```

## 6. 主系统数据表

```
ai_conversation
ai_message
ai_call_log
```

## 7. 关键接口

主系统接口：

```
POST /api/student/ai/ask
POST /api/student/ai/solve-image
GET  /api/student/ai/conversations
GET  /api/student/ai/conversations/{id}
```

AI 微服务接口：

```
POST /ai/ask
POST /ai/solve-image
POST /ai/extract-knowledge-points
POST /ai/analyze-mistakes
```

## 8. 限流规则

1. 普通学生每分钟最多调用 10 次。
2. 图片解析每分钟最多调用 3 次。
3. AI 服务超时时间默认 30 秒。
4. 超时后返回降级提示。

## 9. 异常情况

1. AI 服务不可用。
2. OCR 识别失败。
3. 图片格式非法。
4. 模型推理超时。
5. 返回内容为空。
6. 用户调用过于频繁。