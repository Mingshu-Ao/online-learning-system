<template>
  <section class="hero-card">
    <div>
      <p class="section-card__eyebrow">Learning Hub</p>
      <h1 class="hero-title">课程列表</h1>
      <p class="muted">公开课程、学习进度和角色入口都从这里进入。</p>
    </div>
    <div class="grid" style="align-content: start;">
      <StatCard label="课程总数" :value="coursePage.total" hint="当前检索结果" />
      <StatCard
        label="今日学习"
        :value="learningStats ? formatDuration(learningStats.todayStudySeconds) : '未登录'"
        hint="登录后可查看个性化数据"
      />
    </div>
  </section>

  <SectionCard title="课程搜索" subtitle="支持关键字、分类和难度过滤。">
    <div class="filter-row">
      <input v-model.trim="query.keyword" class="search-input" placeholder="搜索课程名称" @keyup.enter="loadCourses(1)" />
      <input v-model.trim="query.category" class="search-input" placeholder="分类，例如 Java" @keyup.enter="loadCourses(1)" />
      <select v-model="query.difficulty">
        <option value="">全部难度</option>
        <option value="BEGINNER">BEGINNER</option>
        <option value="INTERMEDIATE">INTERMEDIATE</option>
        <option value="ADVANCED">ADVANCED</option>
      </select>
      <button class="primary-button" @click="loadCourses(1)">搜索</button>
    </div>
  </SectionCard>

  <div v-if="loading" class="empty-state">课程加载中...</div>
  <div v-else-if="coursePage.records.length === 0" class="empty-state">暂无匹配课程。</div>
  <div v-else class="course-grid">
    <article v-for="course in coursePage.records" :key="course.id" class="course-card">
      <div class="course-card__cover" :style="coverStyle(course.coverUrl)"></div>
      <h3 class="course-card__title">{{ course.title }}</h3>
      <p class="muted">{{ course.teacherName }} · {{ course.difficulty || '未设置难度' }}</p>
      <p class="muted">{{ course.studentCount }} 名学员已加入</p>
      <div class="inline-actions">
        <RouterLink class="primary-button" :to="`/courses/${course.id}`">查看详情</RouterLink>
        <RouterLink v-if="authStore.hasRole('STUDENT')" class="secondary-button" :to="`/ai-assistant?courseId=${course.id}`">
          AI 助教
        </RouterLink>
      </div>
    </article>
  </div>

  <PaginationBar :total="coursePage.total" :page-num="query.pageNum" :page-size="query.pageSize" @update:page-num="loadCourses" />
</template>

<script setup lang="ts">
import { onMounted, reactive, ref } from 'vue'
import { RouterLink } from 'vue-router'
import PaginationBar from '@/components/PaginationBar.vue'
import SectionCard from '@/components/SectionCard.vue'
import StatCard from '@/components/StatCard.vue'
import { fetchCourseList } from '@/api/courseApi'
import { fetchLearningStats } from '@/api/learningApi'
import { useAuthStore } from '@/store/auth'
import type { LearningStats } from '@/types/course'
import type { PageResult } from '@/types/common'
import type { CourseListItem } from '@/types/course'
import { formatDuration } from '@/utils/format'

const authStore = useAuthStore()
const loading = ref(false)
const learningStats = ref<LearningStats | null>(null)
const coursePage = ref<PageResult<CourseListItem>>({ total: 0, records: [] })
const query = reactive({
  pageNum: 1,
  pageSize: 9,
  keyword: '',
  category: '',
  difficulty: ''
})

function coverStyle(url: string | null) {
  if (!url) {
    return undefined
  }
  return {
    backgroundImage: `linear-gradient(rgba(24, 49, 91, 0.25), rgba(24, 49, 91, 0.25)), url(${url})`,
    backgroundSize: 'cover',
    backgroundPosition: 'center'
  }
}

async function loadCourses(page = query.pageNum) {
  loading.value = true
  query.pageNum = page
  try {
    coursePage.value = await fetchCourseList(query)
  } finally {
    loading.value = false
  }
}

async function loadLearningStats() {
  if (!authStore.hasRole('STUDENT')) {
    return
  }
  try {
    learningStats.value = await fetchLearningStats()
  } catch {
    learningStats.value = null
  }
}

onMounted(() => {
  loadCourses(1)
  loadLearningStats()
})
</script>
