<template>
  <section class="hero-card">
    <div>
      <p class="section-card__eyebrow">Teacher Console</p>
      <h1 class="hero-title">教师课程管理</h1>
      <p class="muted">
        当前后端还没有提供教师课程列表接口，所以这个页面聚焦在新建课程、按课程 ID 加载、章节维护、资源元数据维护和提交审核。
      </p>
    </div>
    <div class="grid">
      <StatCard label="当前课程" :value="currentCourse?.id ?? '--'" />
      <StatCard label="章节数" :value="currentCourse?.chapters.length ?? 0" />
    </div>
  </section>

  <div class="detail-grid">
    <SectionCard title="课程信息" subtitle="支持创建课程和更新当前已加载课程。">
      <div class="form-grid">
        <label class="field"><span>课程标题</span><input v-model="courseForm.title" /></label>
        <label class="field"><span>封面 URL</span><input v-model="courseForm.coverUrl" /></label>
        <label class="field"><span>分类</span><input v-model="courseForm.category" /></label>
        <label class="field"><span>难度</span><input v-model="courseForm.difficulty" placeholder="BEGINNER / INTERMEDIATE / ADVANCED" /></label>
        <label class="field" style="grid-column: 1 / -1;"><span>课程简介</span><textarea v-model="courseForm.summary" /></label>
      </div>
      <div class="inline-actions">
        <button class="primary-button" @click="createCourse">新建课程</button>
        <button class="secondary-button" :disabled="!currentCourse" @click="updateCourse">更新当前课程</button>
        <button class="secondary-button" :disabled="!currentCourse" @click="submitReview">提交审核</button>
      </div>
      <div class="filter-row">
        <input v-model.number="courseLookupId" type="number" min="1" placeholder="输入课程 ID 加载详情" />
        <button class="ghost-button" @click="loadCourseById">按 ID 加载课程</button>
      </div>
    </SectionCard>

    <SectionCard title="章节维护" subtitle="新增章节、更新章节并按 sortOrder 排序。">
      <div class="form-grid">
        <label class="field"><span>章节标题</span><input v-model="chapterForm.title" /></label>
        <label class="field"><span>排序号</span><input v-model.number="chapterForm.sortOrder" type="number" min="1" /></label>
        <label class="field"><span>父章节 ID</span><input v-model.number="chapterForm.parentId" type="number" min="1" placeholder="可选" /></label>
        <label class="field"><span>编辑章节 ID</span><input v-model.number="selectedChapterId" type="number" min="1" placeholder="可选" /></label>
      </div>
      <div class="inline-actions">
        <button class="primary-button" :disabled="!currentCourse" @click="createChapter">新增章节</button>
        <button class="secondary-button" :disabled="!selectedChapterId" @click="updateChapter">更新章节</button>
        <button class="ghost-button" :disabled="!currentCourse" @click="sortChapters">按当前排序号重排</button>
      </div>
      <div class="quiz-list">
        <article v-for="chapter in currentCourse?.chapters || []" :key="chapter.id" class="chapter-card">
          <strong>{{ chapter.sortOrder }}. {{ chapter.title }}</strong>
          <p class="muted">chapterId={{ chapter.id }} · resources={{ chapter.resources.length }}</p>
        </article>
      </div>
    </SectionCard>
  </div>

  <SectionCard title="资源元数据" subtitle="按后端约定提交资源信息，不在页面里硬编码后端地址。">
    <div class="form-grid">
      <label class="field"><span>章节 ID</span><input v-model.number="resourceForm.chapterId" type="number" min="1" /></label>
      <label class="field"><span>资源标题</span><input v-model="resourceForm.title" /></label>
      <label class="field"><span>资源类型</span><input v-model="resourceForm.resourceType" placeholder="VIDEO / DOCUMENT / IMAGE" /></label>
      <label class="field"><span>访问类型</span><input v-model="resourceForm.accessType" placeholder="PUBLIC / PRIVATE" /></label>
      <label class="field"><span>原始文件名</span><input v-model="resourceForm.originalFileName" /></label>
      <label class="field"><span>MIME Type</span><input v-model="resourceForm.mimeType" /></label>
      <label class="field"><span>文件大小(bytes)</span><input v-model.number="resourceForm.fileSize" type="number" min="1" /></label>
      <label class="field"><span>时长(秒)</span><input v-model.number="resourceForm.durationSeconds" type="number" min="0" /></label>
      <label class="field" style="grid-column: 1 / -1;"><span>封面 URL</span><input v-model="resourceForm.coverUrl" /></label>
    </div>
    <button class="primary-button" :disabled="!currentCourse" @click="uploadResourceMetadata">保存资源元数据</button>
  </SectionCard>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import SectionCard from '@/components/SectionCard.vue'
import StatCard from '@/components/StatCard.vue'
import { fetchCourseDetail } from '@/api/courseApi'
import {
  createTeacherChapter,
  createTeacherCourse,
  sortTeacherChapters,
  submitTeacherCourseReview,
  updateTeacherChapter,
  updateTeacherCourse,
  uploadTeacherResourceMetadata
} from '@/api/teacherApi'
import { useAppStore } from '@/store/app'
import type { CourseDetail } from '@/types/course'

const appStore = useAppStore()
const currentCourse = ref<CourseDetail | null>(null)
const courseLookupId = ref<number | null>(null)
const selectedChapterId = ref<number | null>(null)
const courseForm = reactive({
  title: '',
  summary: '',
  coverUrl: '',
  category: '',
  difficulty: 'BEGINNER'
})
const chapterForm = reactive({
  parentId: null as number | null,
  title: '',
  sortOrder: 1
})
const resourceForm = reactive({
  chapterId: 0,
  title: '',
  resourceType: 'VIDEO',
  accessType: 'PRIVATE',
  originalFileName: '',
  mimeType: 'video/mp4',
  fileSize: 0,
  durationSeconds: 0,
  coverUrl: ''
})

function syncCourseForm(course: CourseDetail) {
  courseForm.title = course.title
  courseForm.summary = course.summary || ''
  courseForm.coverUrl = course.coverUrl || ''
  courseForm.category = course.category || ''
  courseForm.difficulty = course.difficulty || 'BEGINNER'
}

async function loadCourseById() {
  if (!courseLookupId.value) {
    return
  }
  currentCourse.value = await fetchCourseDetail(courseLookupId.value)
  syncCourseForm(currentCourse.value)
  resourceForm.chapterId = currentCourse.value.chapters[0]?.id ?? 0
}

async function createCourse() {
  currentCourse.value = await createTeacherCourse(courseForm)
  syncCourseForm(currentCourse.value)
  courseLookupId.value = currentCourse.value.id
  appStore.setNotice(`课程 ${currentCourse.value.title} 已创建。`, 'success')
}

async function updateCourse() {
  if (!currentCourse.value) {
    return
  }
  currentCourse.value = await updateTeacherCourse(currentCourse.value.id, courseForm)
  syncCourseForm(currentCourse.value)
  appStore.setNotice('课程信息已更新。', 'success')
}

async function submitReview() {
  if (!currentCourse.value) {
    return
  }
  currentCourse.value = await submitTeacherCourseReview(currentCourse.value.id)
  appStore.setNotice('课程已提交审核。', 'success')
}

async function createChapter() {
  if (!currentCourse.value) {
    return
  }
  await createTeacherChapter(currentCourse.value.id, chapterForm)
  await loadCourseById()
  appStore.setNotice('章节已新增。', 'success')
}

async function updateChapter() {
  if (!selectedChapterId.value) {
    return
  }
  await updateTeacherChapter(selectedChapterId.value, chapterForm)
  await loadCourseById()
  appStore.setNotice('章节已更新。', 'success')
}

async function sortChapters() {
  if (!currentCourse.value) {
    return
  }
  const chapters = currentCourse.value.chapters.map((chapter) => ({
    chapterId: chapter.id,
    parentId: chapter.parentId,
    sortOrder: chapter.sortOrder
  }))
  await sortTeacherChapters(currentCourse.value.id, chapters)
  await loadCourseById()
  appStore.setNotice('章节顺序已同步。', 'success')
}

async function uploadResourceMetadata() {
  if (!currentCourse.value) {
    return
  }
  await uploadTeacherResourceMetadata({
    ...resourceForm,
    courseId: currentCourse.value.id,
    coverUrl: resourceForm.coverUrl || null,
    durationSeconds: resourceForm.durationSeconds || null
  })
  await loadCourseById()
  appStore.setNotice('资源元数据已保存。', 'success')
}
</script>
