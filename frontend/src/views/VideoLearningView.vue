<template>
  <div v-if="loading" class="empty-state">学习页加载中...</div>
  <template v-else-if="course && activeResource">
    <section class="hero-card">
      <div>
        <p class="section-card__eyebrow">Video Learning</p>
        <h1 class="hero-title">{{ activeResource.title }}</h1>
        <p class="muted">{{ course.title }} · {{ activeChapter?.title || '未归类章节' }}</p>
        <div class="meta-row" style="margin-top: 14px;">
          <span class="pill">学习进度 {{ progress ? `${progress.completionPercent.toFixed(1)}%` : '0%' }}</span>
          <span class="pill">资源时长 {{ formatDuration(activeResource.durationSeconds) }}</span>
          <span class="pill">上次学习 {{ progress?.lastStudyAt ? formatDateTime(progress.lastStudyAt) : '首次学习' }}</span>
        </div>
      </div>
      <div class="grid">
        <StatCard label="已完成视频" :value="progress ? `${progress.completedVideoCount}/${progress.totalVideoCount}` : '0/0'" />
        <StatCard label="有效学习时长" :value="progress ? formatDuration(progress.totalEffectiveStudySeconds) : '0s'" />
      </div>
    </section>

    <div class="detail-grid">
      <SectionCard title="视频播放" subtitle="页面会定时上报学习进度。">
        <div class="section-card__body">
          <video
            v-if="accessUrl && activeResource.resourceType === 'VIDEO'"
            ref="videoRef"
            controls
            playsinline
            :src="accessUrl"
            style="width: 100%; border-radius: 22px; background: #0f1728;"
            @ended="reportProgress(true)"
          />
          <div v-else class="empty-state">
            当前资源不是视频或尚未获取访问地址。
            <a v-if="accessUrl" :href="accessUrl" target="_blank" rel="noreferrer">打开资源</a>
          </div>
          <div class="inline-actions">
            <button class="secondary-button" @click="loadResourceAccess">刷新访问地址</button>
            <RouterLink class="ghost-button" :to="`/courses/${course.id}`">返回课程详情</RouterLink>
          </div>
        </div>
      </SectionCard>

      <SectionCard title="课程目录" subtitle="同课程视频可在这里切换。">
        <div class="chapter-list">
          <article v-for="chapter in course.chapters" :key="chapter.id" class="chapter-card">
            <h3 class="item-title">{{ chapter.title }}</h3>
            <div class="resource-list">
              <button
                v-for="resource in chapter.resources.filter((item) => item.resourceType === 'VIDEO')"
                :key="resource.id"
                class="secondary-button"
                @click="switchResource(resource.id)"
              >
                {{ resource.title }}
              </button>
            </div>
          </article>
        </div>
      </SectionCard>
    </div>
  </template>
  <div v-else class="empty-state">未找到当前学习资源。</div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { RouterLink, useRoute, useRouter } from 'vue-router'
import SectionCard from '@/components/SectionCard.vue'
import StatCard from '@/components/StatCard.vue'
import { fetchCourseDetail, fetchResourceAccessUrl } from '@/api/courseApi'
import { fetchCourseProgress, reportVideoProgress } from '@/api/learningApi'
import type { CourseChapter, CourseDetail, CourseLearningProgress, CourseResource } from '@/types/course'
import { formatDateTime, formatDuration } from '@/utils/format'

const route = useRoute()
const router = useRouter()
const videoRef = ref<HTMLVideoElement | null>(null)
const loading = ref(false)
const course = ref<CourseDetail | null>(null)
const progress = ref<CourseLearningProgress | null>(null)
const accessUrl = ref('')
let progressTimer: number | null = null

const activeResourceId = computed(() => Number(route.params.resourceId))
const allResources = computed(() => (course.value?.chapters ?? []).flatMap((chapter) => chapter.resources))
const activeResource = computed<CourseResource | null>(() => allResources.value.find((item) => item.id === activeResourceId.value) ?? null)
const activeChapter = computed<CourseChapter | null>(() =>
  course.value?.chapters.find((chapter) => chapter.resources.some((item) => item.id === activeResourceId.value)) ?? null
)

async function loadPage() {
  loading.value = true
  try {
    const courseId = Number(route.params.courseId)
    const [courseDetail, progressData] = await Promise.all([
      fetchCourseDetail(courseId),
      fetchCourseProgress(courseId)
    ])
    course.value = courseDetail
    progress.value = progressData
    await loadResourceAccess()
  } finally {
    loading.value = false
  }
}

async function loadResourceAccess() {
  if (!activeResource.value) {
    accessUrl.value = ''
    return
  }
  const result = await fetchResourceAccessUrl(activeResource.value.id)
  accessUrl.value = result.accessUrl
}

async function reportProgress(forceComplete = false) {
  if (!videoRef.value || !course.value || !activeResource.value || !activeChapter.value) {
    return
  }
  const payload = {
    courseId: course.value.id,
    chapterId: activeChapter.value.id,
    resourceId: activeResource.value.id,
    currentPosition: Math.floor(forceComplete ? videoRef.value.duration || videoRef.value.currentTime : videoRef.value.currentTime),
    duration: Math.max(1, Math.floor(videoRef.value.duration || activeResource.value.durationSeconds || 1)),
    playbackRate: videoRef.value.playbackRate || 1,
    clientTimestamp: Date.now()
  }
  try {
    await reportVideoProgress(payload)
    progress.value = await fetchCourseProgress(course.value.id)
  } catch {
    // Ignore transient report errors and keep playback uninterrupted.
  }
}

function switchResource(resourceId: number) {
  router.push(`/learn/${route.params.courseId}/${resourceId}`)
}

function startProgressTimer() {
  stopProgressTimer()
  progressTimer = window.setInterval(() => {
    reportProgress(false)
  }, 15000)
}

function stopProgressTimer() {
  if (progressTimer !== null) {
    window.clearInterval(progressTimer)
    progressTimer = null
  }
}

onMounted(async () => {
  await loadPage()
  startProgressTimer()
})

onUnmounted(() => {
  reportProgress(false)
  stopProgressTimer()
})
</script>
