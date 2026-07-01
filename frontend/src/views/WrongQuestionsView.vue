<template>
  <SectionCard title="错题本" subtitle="自动沉淀未掌握错题，并支持重做与标记掌握。">
    <template #actions>
      <div class="filter-row">
        <input v-model.number="filters.courseId" type="number" min="1" placeholder="按课程 ID 筛选" />
        <select v-model="filters.status">
          <option value="">全部状态</option>
          <option value="UNMASTERED">UNMASTERED</option>
          <option value="MASTERED">MASTERED</option>
        </select>
        <button class="primary-button" @click="loadWrongQuestions">刷新列表</button>
      </div>
    </template>

    <div v-if="loading" class="empty-state">错题加载中...</div>
    <div v-else-if="wrongQuestions.length === 0" class="empty-state">当前没有错题记录。</div>
    <div v-else class="quiz-list">
      <article v-for="item in wrongQuestions" :key="item.id" class="wrong-card">
        <div class="meta-row" style="justify-content: space-between;">
          <strong>{{ item.stem }}</strong>
          <span class="tag">{{ item.status }} · {{ item.wrongCount }} 次</span>
        </div>
        <p class="muted">题型：{{ item.questionType }} · 知识点：{{ item.knowledgePoint || '未标注' }}</p>
        <p class="muted">标准答案：{{ formatAnswer(item.standardAnswer) }}</p>
        <p class="muted">解析：{{ item.analysis || '暂无解析' }}</p>
        <div class="inline-actions">
          <button class="secondary-button" @click="redo(item.id)">重做一遍</button>
          <button class="primary-button" @click="markMastered(item.id)">标记已掌握</button>
        </div>
      </article>
    </div>
  </SectionCard>
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import SectionCard from '@/components/SectionCard.vue'
import { fetchWrongQuestions, markWrongQuestionMastered, redoWrongQuestion } from '@/api/quizApi'
import type { WrongQuestion } from '@/types/quiz'
import { useAppStore } from '@/store/app'

const appStore = useAppStore()
const loading = ref(false)
const wrongQuestions = ref<WrongQuestion[]>([])
const filters = reactive({
  courseId: undefined as number | undefined,
  status: ''
})

function formatAnswer(value: unknown) {
  if (value == null) {
    return '未提供'
  }
  return typeof value === 'string' ? value : JSON.stringify(value)
}

async function loadWrongQuestions() {
  loading.value = true
  try {
    wrongQuestions.value = await fetchWrongQuestions({
      courseId: filters.courseId,
      status: filters.status || undefined
    })
  } finally {
    loading.value = false
  }
}

async function redo(id: number) {
  const result = await redoWrongQuestion(id)
  appStore.setNotice(`已打开错题重做视图：${result.stem}`, 'success')
}

async function markMastered(id: number) {
  await markWrongQuestionMastered(id)
  appStore.setNotice('已标记为掌握。', 'success')
  await loadWrongQuestions()
}

onMounted(loadWrongQuestions)
</script>
