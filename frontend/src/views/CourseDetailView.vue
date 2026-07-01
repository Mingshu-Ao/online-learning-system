<template>
  <div v-if="loading" class="empty-state">课程详情加载中...</div>
  <template v-else-if="course">
    <section class="hero-card">
      <div>
        <p class="section-card__eyebrow">Course Detail</p>
        <h1 class="hero-title">{{ course.title }}</h1>
        <p class="muted">{{ course.summary || '暂无课程简介。' }}</p>
        <div class="meta-row" style="margin-top: 16px;">
          <span class="pill">{{ course.category || '未分类' }}</span>
          <span class="pill">{{ course.difficulty || '未设置难度' }}</span>
          <span class="pill">{{ course.teacherName || '未知教师' }}</span>
          <span class="pill">{{ course.studentCount }} 人学习</span>
        </div>
      </div>

      <SectionCard title="快速入口" subtitle="从课程详情直达学习、测验和 AI 助教。">
        <div class="section-card__body">
          <RouterLink v-if="firstVideo" class="primary-button" :to="`/learn/${course.id}/${firstVideo.id}`">
            开始视频学习
          </RouterLink>
          <RouterLink v-if="authStore.hasRole('STUDENT')" class="secondary-button" :to="`/ai-assistant?courseId=${course.id}`">
            打开 AI 助教
          </RouterLink>
          <div class="filter-row">
            <input v-model.number="paperIdInput" type="number" min="1" placeholder="输入试卷 ID" />
            <button class="secondary-button" @click="goToQuiz">进入测验页</button>
          </div>
          <p class="muted">后端当前未提供课程试卷列表接口，所以这里使用试卷 ID 直达测验页。</p>
        </div>
      </SectionCard>
    </section>

    <div class="detail-grid">
      <SectionCard title="章节结构" subtitle="按章节查看资源清单。">
        <div class="chapter-list">
          <article v-for="chapter in course.chapters" :key="chapter.id" class="chapter-card">
            <h3 class="item-title">{{ chapter.sortOrder }}. {{ chapter.title }}</h3>
            <div v-if="chapter.resources.length" class="resource-list">
              <div v-for="resource in chapter.resources" :key="resource.id" class="resource-card">
                <strong>{{ resource.title }}</strong>
                <p class="muted">{{ resource.resourceType }} · {{ resource.accessType }}</p>
                <RouterLink
                  v-if="resource.resourceType === 'VIDEO' && authStore.hasRole('STUDENT')"
                  class="secondary-button"
                  :to="`/learn/${course.id}/${resource.id}`"
                >
                  去学习
                </RouterLink>
              </div>
            </div>
            <p v-else class="muted">该章节暂未上传资源。</p>
          </article>
        </div>
      </SectionCard>

      <SectionCard title="课程概览" subtitle="帮助你快速判断是否进入学习。">
        <div class="grid">
          <StatCard label="章节数" :value="course.chapters.length" />
          <StatCard label="视频数" :value="videoResources.length" />
          <StatCard label="课程状态" :value="course.status" />
        </div>
        <p v-if="course.reviewComment" class="muted">审核备注：{{ course.reviewComment }}</p>
      </SectionCard>
    </div>
  </template>
  <div v-else class="empty-state">未找到该课程。</div>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import SectionCard from '@/components/SectionCard.vue'
import StatCard from '@/components/StatCard.vue'
import { fetchCourseDetail } from '@/api/courseApi'
import { useAuthStore } from '@/store/auth'
import type { CourseDetail, CourseResource } from '@/types/course'

const route = useRoute()
const router = useRouter()
const authStore = useAuthStore()
const loading = ref(false)
const course = ref<CourseDetail | null>(null)
const paperIdInput = ref<number | null>(null)

const videoResources = computed(() =>
  (course.value?.chapters ?? []).flatMap((chapter) => chapter.resources).filter((resource) => resource.resourceType === 'VIDEO')
)
const firstVideo = computed<CourseResource | null>(() => videoResources.value[0] ?? null)

async function loadCourse() {
  loading.value = true
  try {
    course.value = await fetchCourseDetail(Number(route.params.courseId))
  } finally {
    loading.value = false
  }
}

function goToQuiz() {
  if (!paperIdInput.value) {
    return
  }
  router.push(`/quiz/${paperIdInput.value}`)
}

onMounted(loadCourse)
</script>
