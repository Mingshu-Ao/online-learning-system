<template>
  <section class="hero-card">
    <div>
      <p class="section-card__eyebrow">AI Assistant</p>
      <h1 class="hero-title">AI 智能助教</h1>
      <p class="muted">文本提问和图片错题解析都通过主系统鉴权与限流后，再转发给 FastAPI 微服务。</p>
    </div>
    <div class="grid">
      <StatCard label="当前课程" :value="courseId || '--'" />
      <StatCard label="历史会话" :value="conversations.length" />
    </div>
  </section>

  <div class="detail-grid">
    <SectionCard title="提问面板" subtitle="支持文本问答和图片解析。">
      <div class="section-card__body">
        <label class="field">
          <span>课程 ID</span>
          <input v-model.number="courseId" type="number" min="1" placeholder="请输入课程 ID" />
        </label>
        <label class="field">
          <span>文本问题</span>
          <textarea v-model="questionText" placeholder="例如：递归和迭代的区别是什么？"></textarea>
        </label>
        <div class="inline-actions">
          <button class="primary-button" :disabled="submitting || !courseId || !questionText.trim()" @click="submitQuestion">
            {{ submitting ? '提交中...' : '发送文本问题' }}
          </button>
          <input type="file" accept="image/png,image/jpeg,image/webp" @change="handleFileChange" />
          <button class="secondary-button" :disabled="submitting || !courseId || !selectedImage" @click="submitImage">
            上传图片解析
          </button>
        </div>
        <div v-if="latestResponse" class="chat-message chat-message--assistant">
          <div class="meta-row" style="justify-content: space-between;">
            <strong>最新回答</strong>
            <span class="tag">{{ latestResponse.degraded ? '降级提示' : '正常返回' }}</span>
          </div>
          <p>{{ latestResponse.message }}</p>
          <ul>
            <li v-for="step in latestResponse.solutionSteps" :key="step">{{ step }}</li>
          </ul>
          <p class="muted">知识点：{{ latestResponse.knowledgePoints.join('、') || '未提取' }}</p>
          <div class="quiz-list">
            <article v-for="item in latestResponse.recommendations" :key="`${item.type}-${item.resourceId}-${item.reason}`" class="resource-card">
              <strong>{{ item.type }} {{ item.resourceId ?? '--' }}</strong>
              <p class="muted">{{ item.reason }}</p>
            </article>
          </div>
        </div>
      </div>
    </SectionCard>

    <SectionCard title="会话历史" subtitle="选择任一会话查看消息流和结构化结果。">
      <div class="chat-list">
        <button
          v-for="conversation in conversations"
          :key="conversation.conversationId"
          class="resource-card"
          @click="loadConversationDetail(conversation.conversationId)"
        >
          <strong>{{ conversation.title }}</strong>
          <p class="muted">{{ conversation.latestSummary || '暂无摘要' }}</p>
        </button>
        <div v-if="conversations.length === 0" class="empty-state">还没有 AI 会话记录。</div>
      </div>
      <div v-if="conversationDetail" class="chat-list">
        <article
          v-for="message in conversationDetail.messages"
          :key="message.messageId"
          class="chat-message"
          :class="message.role === 'ASSISTANT' ? 'chat-message--assistant' : 'chat-message--user'"
        >
          <div class="meta-row" style="justify-content: space-between;">
            <strong>{{ message.role }}</strong>
            <span class="muted">{{ formatDateTime(message.createdAt) }}</span>
          </div>
          <p>{{ message.content }}</p>
          <p v-if="message.fileName" class="muted">附件：{{ message.fileName }}</p>
          <div v-if="message.structuredResponse" class="resource-card">
            <strong>{{ message.structuredResponse.message }}</strong>
            <p class="muted">推荐数：{{ message.structuredResponse.recommendations.length }}</p>
          </div>
        </article>
      </div>
    </SectionCard>
  </div>
</template>

<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { useRoute } from 'vue-router'
import SectionCard from '@/components/SectionCard.vue'
import StatCard from '@/components/StatCard.vue'
import { askAiQuestion, fetchAiConversationDetail, fetchAiConversations, solveAiImage } from '@/api/aiApi'
import type { AiAssistantResponse, AiConversationDetail, AiConversationSummary } from '@/types/ai'
import { formatDateTime } from '@/utils/format'

const route = useRoute()
const courseId = ref<number | null>(route.query.courseId ? Number(route.query.courseId) : null)
const questionText = ref('')
const selectedImage = ref<File | null>(null)
const submitting = ref(false)
const latestResponse = ref<AiAssistantResponse | null>(null)
const conversations = ref<AiConversationSummary[]>([])
const conversationDetail = ref<AiConversationDetail | null>(null)

async function loadConversations() {
  conversations.value = await fetchAiConversations()
  if (conversations.value.length > 0 && !conversationDetail.value) {
    await loadConversationDetail(conversations.value[0].conversationId)
  }
}

async function loadConversationDetail(conversationId: number) {
  conversationDetail.value = await fetchAiConversationDetail(conversationId)
}

function handleFileChange(event: Event) {
  const input = event.target as HTMLInputElement
  selectedImage.value = input.files?.[0] ?? null
}

async function submitQuestion() {
  if (!courseId.value) {
    return
  }
  submitting.value = true
  try {
    latestResponse.value = await askAiQuestion(courseId.value, questionText.value)
    questionText.value = ''
    await loadConversations()
    if (latestResponse.value.conversationId) {
      await loadConversationDetail(latestResponse.value.conversationId)
    }
  } finally {
    submitting.value = false
  }
}

async function submitImage() {
  if (!courseId.value || !selectedImage.value) {
    return
  }
  submitting.value = true
  try {
    latestResponse.value = await solveAiImage(courseId.value, selectedImage.value)
    selectedImage.value = null
    await loadConversations()
    if (latestResponse.value.conversationId) {
      await loadConversationDetail(latestResponse.value.conversationId)
    }
  } finally {
    submitting.value = false
  }
}

onMounted(loadConversations)
</script>
