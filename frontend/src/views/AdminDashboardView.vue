<template>
  <section class="hero-card">
    <div>
      <p class="section-card__eyebrow">Admin Console</p>
      <h1 class="hero-title">管理端基础页面</h1>
      <p class="muted">这里集中展示运营看板、统计趋势、公告管理和审计日志分页查询。</p>
    </div>
    <div class="dashboard-grid">
      <StatCard label="总用户数" :value="dashboard?.totalUsers ?? '--'" />
      <StatCard label="DAU" :value="dashboard?.dailyActiveUsers ?? '--'" />
      <StatCard label="课程总数" :value="dashboard?.totalCourses ?? '--'" />
      <StatCard label="今日学习时长" :value="dashboard ? formatDuration(dashboard.todayLearningDurationSeconds) : '--'" />
      <StatCard label="自习室在线" :value="dashboard?.currentStudyRoomOnlineUsers ?? '--'" />
      <StatCard label="今日 AI 调用" :value="dashboard?.todayAiCallCount ?? '--'" />
    </div>
  </section>

  <SectionCard title="统计趋势" subtitle="按天查看近一段时间运营概览。">
    <template #actions>
      <div class="inline-actions">
        <select v-model.number="statisticsDays" @change="loadStatistics">
          <option :value="7">近 7 天</option>
          <option :value="14">近 14 天</option>
          <option :value="30">近 30 天</option>
        </select>
      </div>
    </template>
    <table v-if="statistics" class="table">
      <thead>
        <tr>
          <th>日期</th>
          <th>新增用户</th>
          <th>DAU</th>
          <th>AI 调用</th>
          <th>学习时长</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="item in statistics.items" :key="item.date">
          <td>{{ item.date }}</td>
          <td>{{ item.newUsers }}</td>
          <td>{{ item.dailyActiveUsers }}</td>
          <td>{{ item.aiCallCount }}</td>
          <td>{{ formatDuration(item.learningDurationSeconds) }}</td>
        </tr>
      </tbody>
    </table>
  </SectionCard>

  <div class="detail-grid">
    <SectionCard title="公告管理" subtitle="支持分页查询、创建、更新和下线。">
      <div class="form-grid">
        <label class="field"><span>标题</span><input v-model="announcementForm.title" /></label>
        <label class="field"><span>发布时间</span><input v-model="announcementForm.publishAt" type="datetime-local" /></label>
        <label class="field"><span>可见范围</span><input v-model="announcementForm.visibility" placeholder="ALL / STUDENT / TEACHER" /></label>
        <label class="field"><span>状态</span><input v-model="announcementForm.status" placeholder="DRAFT / PUBLISHED / OFFLINE" /></label>
        <label class="field" style="grid-column: 1 / -1;"><span>内容</span><textarea v-model="announcementForm.content" /></label>
      </div>
      <div class="inline-actions">
        <button class="primary-button" @click="saveAnnouncement">{{ editingAnnouncementId ? '更新公告' : '创建公告' }}</button>
        <button class="ghost-button" @click="resetAnnouncementForm">重置</button>
      </div>
      <table class="table">
        <thead>
          <tr>
            <th>标题</th>
            <th>状态</th>
            <th>范围</th>
            <th>发布时间</th>
            <th>操作</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in announcements.records" :key="item.id">
            <td>{{ item.title }}</td>
            <td>{{ item.status }}</td>
            <td>{{ item.visibility }}</td>
            <td>{{ formatDateTime(item.publishAt) }}</td>
            <td>
              <div class="inline-actions">
                <button class="secondary-button" @click="editAnnouncement(item.id)">编辑</button>
                <button class="danger-button" @click="offlineAnnouncement(item.id)">下线</button>
              </div>
            </td>
          </tr>
        </tbody>
      </table>
      <PaginationBar :total="announcements.total" :page-num="announcementQuery.pageNum" :page-size="announcementQuery.pageSize" @update:page-num="loadAnnouncements" />
    </SectionCard>

    <SectionCard title="审计日志" subtitle="所有日志查询均走分页接口。">
      <div class="inline-actions">
        <button class="secondary-button" @click="switchLogTab('login')">登录日志</button>
        <button class="secondary-button" @click="switchLogTab('operation')">操作日志</button>
        <button class="secondary-button" @click="switchLogTab('resource')">资源访问</button>
        <button class="secondary-button" @click="switchLogTab('error')">异常日志</button>
      </div>
      <table class="table">
        <thead>
          <tr>
            <th v-for="header in logHeaders" :key="header">{{ header }}</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="row in logDisplayRows" :key="row.id">
            <td v-for="cell in row.cells" :key="`${row.id}-${cell}`">{{ cell }}</td>
          </tr>
        </tbody>
      </table>
      <PaginationBar :total="logTotal" :page-num="logQuery.pageNum" :page-size="logQuery.pageSize" @update:page-num="loadLogs" />
    </SectionCard>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import PaginationBar from '@/components/PaginationBar.vue'
import SectionCard from '@/components/SectionCard.vue'
import StatCard from '@/components/StatCard.vue'
import {
  createAnnouncement,
  deleteAnnouncement,
  fetchAdminDashboard,
  fetchAdminStatistics,
  fetchAnnouncements,
  fetchErrorLogs,
  fetchLoginLogs,
  fetchOperationLogs,
  fetchResourceAccessLogs,
  updateAnnouncement
} from '@/api/adminApi'
import type {
  AdminDashboard,
  AdminStatistics,
  Announcement,
  LoginLog,
  OperationLog,
  ResourceAccessLog,
  SystemErrorLog
} from '@/types/admin'
import type { PageResult } from '@/types/common'
import { formatDateTime, formatDuration } from '@/utils/format'
import { useAppStore } from '@/store/app'

const appStore = useAppStore()
const dashboard = ref<AdminDashboard | null>(null)
const statistics = ref<AdminStatistics | null>(null)
const statisticsDays = ref(7)
const announcements = ref<PageResult<Announcement>>({ total: 0, records: [] })
const announcementQuery = reactive({ pageNum: 1, pageSize: 5 })
const announcementForm = reactive({
  title: '',
  content: '',
  visibility: 'ALL',
  status: 'DRAFT',
  publishAt: ''
})
const editingAnnouncementId = ref<number | null>(null)
const activeLogTab = ref<'login' | 'operation' | 'resource' | 'error'>('login')
const logQuery = reactive({ pageNum: 1, pageSize: 6 })
const loginLogs = ref<PageResult<LoginLog>>({ total: 0, records: [] })
const operationLogs = ref<PageResult<OperationLog>>({ total: 0, records: [] })
const resourceLogs = ref<PageResult<ResourceAccessLog>>({ total: 0, records: [] })
const errorLogs = ref<PageResult<SystemErrorLog>>({ total: 0, records: [] })

const logHeaders = computed(() => {
  if (activeLogTab.value === 'login') {
    return ['用户名', '成功', '路径', 'IP', '时间']
  }
  if (activeLogTab.value === 'operation') {
    return ['操作人', '动作', '结果', '请求路径', '时间']
  }
  if (activeLogTab.value === 'resource') {
    return ['用户', '课程', '资源', '类型', '时间']
  }
  return ['错误码', '异常类', '路径', '摘要', '时间']
})

const logDisplayRows = computed(() => {
  if (activeLogTab.value === 'login') {
    return loginLogs.value.records.map((item) => ({
      id: item.id,
      cells: [item.username, item.success ? '成功' : '失败', item.requestPath, item.ipAddress || '--', formatDateTime(item.createdAt)]
    }))
  }
  if (activeLogTab.value === 'operation') {
    return operationLogs.value.records.map((item) => ({
      id: item.id,
      cells: [item.operatorUsername, item.action, item.success ? '成功' : '失败', item.requestPath, formatDateTime(item.createdAt)]
    }))
  }
  if (activeLogTab.value === 'resource') {
    return resourceLogs.value.records.map((item) => ({
      id: item.id,
      cells: [String(item.userId ?? '--'), String(item.courseId ?? '--'), String(item.resourceId ?? '--'), item.resourceType || '--', formatDateTime(item.createdAt)]
    }))
  }
  return errorLogs.value.records.map((item) => ({
    id: item.id,
    cells: [String(item.errorCode ?? '--'), item.exceptionClass, item.requestPath, item.requestSummary || '--', formatDateTime(item.createdAt)]
  }))
})

const logTotal = computed(() => {
  if (activeLogTab.value === 'login') {
    return loginLogs.value.total
  }
  if (activeLogTab.value === 'operation') {
    return operationLogs.value.total
  }
  if (activeLogTab.value === 'resource') {
    return resourceLogs.value.total
  }
  return errorLogs.value.total
})

function resetAnnouncementForm() {
  editingAnnouncementId.value = null
  announcementForm.title = ''
  announcementForm.content = ''
  announcementForm.visibility = 'ALL'
  announcementForm.status = 'DRAFT'
  announcementForm.publishAt = ''
}

function switchLogTab(tab: 'login' | 'operation' | 'resource' | 'error') {
  activeLogTab.value = tab
  loadLogs(1)
}

async function loadDashboard() {
  dashboard.value = await fetchAdminDashboard()
}

async function loadStatistics() {
  statistics.value = await fetchAdminStatistics(statisticsDays.value)
}

async function loadAnnouncements(page = announcementQuery.pageNum) {
  announcementQuery.pageNum = page
  announcements.value = await fetchAnnouncements(announcementQuery)
}

async function editAnnouncement(id: number) {
  const target = announcements.value.records.find((item) => item.id === id)
  if (!target) {
    return
  }
  editingAnnouncementId.value = id
  announcementForm.title = target.title
  announcementForm.content = target.content
  announcementForm.visibility = target.visibility
  announcementForm.status = target.status
  announcementForm.publishAt = target.publishAt ? String(target.publishAt).slice(0, 16) : ''
}

async function saveAnnouncement() {
  const payload = {
    ...announcementForm,
    publishAt: announcementForm.publishAt ? new Date(announcementForm.publishAt).toISOString() : null
  }
  if (editingAnnouncementId.value) {
    await updateAnnouncement(editingAnnouncementId.value, payload)
    appStore.setNotice('公告已更新。', 'success')
  } else {
    await createAnnouncement(payload)
    appStore.setNotice('公告已创建。', 'success')
  }
  resetAnnouncementForm()
  await loadAnnouncements()
}

async function offlineAnnouncement(id: number) {
  await deleteAnnouncement(id)
  appStore.setNotice('公告已下线。', 'success')
  await loadAnnouncements()
}

async function loadLogs(page = logQuery.pageNum) {
  logQuery.pageNum = page
  if (activeLogTab.value === 'login') {
    loginLogs.value = await fetchLoginLogs(logQuery)
  }
  if (activeLogTab.value === 'operation') {
    operationLogs.value = await fetchOperationLogs(logQuery)
  }
  if (activeLogTab.value === 'resource') {
    resourceLogs.value = await fetchResourceAccessLogs(logQuery)
  }
  if (activeLogTab.value === 'error') {
    errorLogs.value = await fetchErrorLogs(logQuery)
  }
}

onMounted(async () => {
  await Promise.all([loadDashboard(), loadStatistics(), loadAnnouncements(), loadLogs()])
})
</script>
