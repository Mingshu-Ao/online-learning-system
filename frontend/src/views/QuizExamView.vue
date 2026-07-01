<template>
  <div v-if="loading" class="empty-state">试卷加载中...</div>
  <template v-else-if="paper">
    <section class="hero-card">
      <div>
        <p class="section-card__eyebrow">Quiz</p>
        <h1 class="hero-title">{{ paper.title }}</h1>
        <p class="muted">总分 {{ paper.totalScore }} · 及格线 {{ paper.passScore }} · 时长 {{ paper.durationMinutes }} 分钟</p>
        <div class="meta-row" style="margin-top: 16px;">
          <span class="pill">剩余时间 {{ countdown }}</span>
          <span class="pill">题目数 {{ paper.questions.length }}</span>
          <span class="pill">状态 {{ result ? result.status : '作答中' }}</span>
        </div>
      </div>
      <div class="grid">
        <StatCard label="考试记录" :value="examRecordId || '--'" />
        <StatCard label="自动判分" :value="result?.objectiveScore ?? '--'" hint="主观题待人工复核" />
      </div>
    </section>

    <SectionCard v-if="!result" title="答题区域" subtitle="客观题会自动判分，主观题提交后进入待复核状态。">
      <div class="quiz-list">
        <article v-for="(question, index) in paper.questions" :key="question.questionId" class="quiz-question">
          <div class="meta-row" style="justify-content: space-between;">
            <strong>第 {{ index + 1 }} 题 · {{ question.questionType }}</strong>
            <span class="tag">{{ question.score }} 分</span>
          </div>
          <p>{{ question.stem }}</p>

          <div v-if="question.questionType === 'SINGLE_CHOICE' || question.questionType === 'MULTIPLE_CHOICE'" class="quiz-list">
            <label v-for="option in question.options" :key="option.optionKey" class="resource-card">
              <input
                v-if="question.questionType === 'SINGLE_CHOICE'"
                :checked="answers[question.questionId] === option.optionKey"
                type="radio"
                :name="`question-${question.questionId}`"
                @change="setSingleChoice(question.questionId, option.optionKey)"
              />
              <input
                v-else
                type="checkbox"
                :checked="isChecked(question.questionId, option.optionKey)"
                @change="toggleMultipleChoice(question.questionId, option.optionKey)"
              />
              <span>{{ option.optionKey }}. {{ option.content }}</span>
            </label>
          </div>

          <div v-else-if="question.questionType === 'TRUE_FALSE'" class="inline-actions">
            <button class="secondary-button" @click="setTrueFalse(question.questionId, true)">正确</button>
            <button class="secondary-button" @click="setTrueFalse(question.questionId, false)">错误</button>
            <span class="muted">当前：{{ answers[question.questionId] === undefined ? '未作答' : String(answers[question.questionId]) }}</span>
          </div>

          <label v-else-if="question.questionType === 'FILL_BLANK'" class="field">
            <span>每行填写一个空的答案</span>
            <textarea
              :value="fillBlankText(question.questionId)"
              placeholder="答案 1&#10;答案 2"
              @input="setFillBlank(question.questionId, ($event.target as HTMLTextAreaElement).value)"
            />
          </label>

          <label v-else class="field">
            <span>简答题答案</span>
            <textarea
              :value="typeof answers[question.questionId] === 'string' ? String(answers[question.questionId]) : ''"
              placeholder="请输入你的解析或答案"
              @input="setShortAnswer(question.questionId, ($event.target as HTMLTextAreaElement).value)"
            />
          </label>
        </article>
      </div>
      <template #actions>
        <button class="primary-button" :disabled="submitting" @click="handleSubmit">
          {{ submitting ? '提交中...' : '提交试卷' }}
        </button>
      </template>
    </SectionCard>

    <SectionCard v-else title="考试结果" subtitle="展示自动判分结果，主观题保留人工复核状态。">
      <div class="grid-3">
        <StatCard label="总分" :value="result.totalScore ?? '--'" />
        <StatCard label="客观题得分" :value="result.objectiveScore ?? '--'" />
        <StatCard label="是否通过" :value="result.pendingReview ? '待复核' : result.passed ? '通过' : '未通过'" />
      </div>
      <div class="quiz-list">
        <article v-for="question in result.questions" :key="question.questionId" class="quiz-question">
          <div class="meta-row" style="justify-content: space-between;">
            <strong>{{ question.stem }}</strong>
            <span class="tag">{{ question.awardedScore ?? '--' }} / {{ question.fullScore }}</span>
          </div>
          <p class="muted">你的答案：{{ formatAnswer(question.userAnswer) }}</p>
          <p class="muted">标准答案：{{ formatAnswer(question.standardAnswer) }}</p>
          <p class="muted">解析：{{ question.analysis || '暂无解析' }}</p>
        </article>
      </div>
    </SectionCard>
  </template>
  <div v-else class="empty-state">未找到试卷。</div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import SectionCard from '@/components/SectionCard.vue'
import StatCard from '@/components/StatCard.vue'
import { fetchExamResult, fetchPaperDetail, startExam, submitExam } from '@/api/quizApi'
import type { ExamResult, ExamSubmitAnswer, PaperDetail } from '@/types/quiz'
import { toCountdownLabel } from '@/utils/format'
import { useRoute } from 'vue-router'

const route = useRoute()
const loading = ref(false)
const submitting = ref(false)
const paper = ref<PaperDetail | null>(null)
const result = ref<ExamResult | null>(null)
const examRecordId = ref<number | null>(null)
const deadlineTime = ref<string | null>(null)
const nowTick = ref(Date.now())
const answers = ref<Record<number, string | string[] | boolean>>({})
let timer: number | null = null

const countdown = computed(() => {
  nowTick.value
  return toCountdownLabel(deadlineTime.value)
})

function setSingleChoice(questionId: number, optionKey: string) {
  answers.value[questionId] = optionKey
}

function isChecked(questionId: number, optionKey: string) {
  const value = answers.value[questionId]
  return Array.isArray(value) ? value.includes(optionKey) : false
}

function toggleMultipleChoice(questionId: number, optionKey: string) {
  const current = Array.isArray(answers.value[questionId]) ? [...(answers.value[questionId] as string[])] : []
  if (current.includes(optionKey)) {
    answers.value[questionId] = current.filter((item) => item !== optionKey)
  } else {
    current.push(optionKey)
    answers.value[questionId] = current.sort()
  }
}

function setTrueFalse(questionId: number, value: boolean) {
  answers.value[questionId] = value
}

function fillBlankText(questionId: number) {
  const value = answers.value[questionId]
  return Array.isArray(value) ? value.join('\n') : ''
}

function setFillBlank(questionId: number, value: string) {
  answers.value[questionId] = value
    .split(/\n+/)
    .map((item) => item.trim())
    .filter(Boolean)
}

function setShortAnswer(questionId: number, value: string) {
  answers.value[questionId] = value
}

function formatAnswer(value: unknown) {
  if (value === null || value === undefined) {
    return '未作答'
  }
  if (typeof value === 'string') {
    return value
  }
  return JSON.stringify(value)
}

function startCountdown() {
  stopCountdown()
  timer = window.setInterval(() => {
    nowTick.value = Date.now()
  }, 1000)
}

function stopCountdown() {
  if (timer !== null) {
    window.clearInterval(timer)
    timer = null
  }
}

function buildSubmitPayload(): ExamSubmitAnswer[] {
  return (paper.value?.questions ?? []).map((question) => ({
    questionId: question.questionId,
    answer: answers.value[question.questionId] ?? null
  }))
}

async function loadExam() {
  loading.value = true
  try {
    const paperId = Number(route.params.paperId)
    paper.value = await fetchPaperDetail(paperId)
    const exam = await startExam(paperId)
    examRecordId.value = exam.examRecordId
    deadlineTime.value = exam.endTime
    startCountdown()
  } finally {
    loading.value = false
  }
}

async function handleSubmit() {
  if (!examRecordId.value) {
    return
  }
  submitting.value = true
  try {
    result.value = await submitExam(examRecordId.value, buildSubmitPayload())
    deadlineTime.value = result.value.deadlineTime
    stopCountdown()
  } finally {
    submitting.value = false
  }
}

onMounted(loadExam)
onUnmounted(stopCountdown)
</script>
