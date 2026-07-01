<template>
  <section class="hero-card">
    <div class="hero-copy">
      <p class="badge">Vue 3 + TypeScript</p>
      <h2>在线学习系统前端骨架</h2>
      <p class="description">
        当前页面已经接入路由、Pinia、Axios 和统一接口响应结构。后续可以继续按模块扩展
        `api`、`views`、`components`、`store` 与 `utils`。
      </p>
    </div>
    <div class="status-panel">
      <h3>后端连接状态</h3>
      <p class="status-value">{{ statusText }}</p>
      <p class="status-meta">{{ statusDetail }}</p>
    </div>
  </section>

  <section class="grid">
    <article class="panel">
      <h3>已准备目录</h3>
      <ul>
        <li>`src/api`：接口请求封装</li>
        <li>`src/router`：路由配置</li>
        <li>`src/store`：全局状态</li>
        <li>`src/views`：页面入口</li>
        <li>`src/utils`：工具函数预留</li>
      </ul>
    </article>

    <article class="panel">
      <h3>公开课程接口</h3>
      <p v-if="courseCount === null">尚未请求课程数据。</p>
      <p v-else>当前返回课程数量：{{ courseCount }}</p>
      <button type="button" class="action-button" @click="loadCourses">
        获取公开课程
      </button>
    </article>
  </section>
</template>

<script setup lang="ts">
import { computed, onMounted, ref } from 'vue'
import { fetchPublicCourses, fetchSystemStatus } from '@/api/systemApi'

const status = ref<'idle' | 'success' | 'error'>('idle')
const statusDetail = ref('等待连接后端服务。')
const courseCount = ref<number | null>(null)

const statusText = computed(() => {
  if (status.value === 'success') {
    return 'Backend Connected'
  }
  if (status.value === 'error') {
    return 'Backend Unavailable'
  }
  return 'Checking'
})

async function loadStatus() {
  try {
    const data = await fetchSystemStatus()
    status.value = 'success'
    statusDetail.value = `${data.serviceName} ${data.version} · ${data.status}`
  } catch (error) {
    status.value = 'error'
    statusDetail.value = error instanceof Error ? error.message : 'unknown error'
  }
}

async function loadCourses() {
  try {
    const courses = await fetchPublicCourses()
    courseCount.value = courses.length
  } catch (error) {
    courseCount.value = null
    status.value = 'error'
    statusDetail.value = error instanceof Error ? error.message : 'unknown error'
  }
}

onMounted(() => {
  loadStatus()
})
</script>

<style scoped>
.hero-card {
  display: grid;
  grid-template-columns: minmax(0, 1.5fr) minmax(280px, 0.9fr);
  gap: 20px;
  padding: 28px;
  border-radius: 28px;
  background: rgba(255, 255, 255, 0.78);
  backdrop-filter: blur(10px);
  box-shadow: 0 24px 60px rgba(26, 42, 73, 0.12);
}

.badge {
  display: inline-flex;
  padding: 6px 12px;
  border-radius: 999px;
  background: #fee7b6;
  color: #8f5b10;
  font-size: 13px;
  font-weight: 700;
}

.hero-copy h2 {
  margin: 14px 0 10px;
  font-size: clamp(24px, 3vw, 36px);
}

.description {
  max-width: 60ch;
  color: #4d5a70;
}

.status-panel,
.panel {
  padding: 24px;
  border-radius: 22px;
  background: rgba(247, 248, 252, 0.92);
  border: 1px solid rgba(101, 116, 146, 0.12);
}

.status-panel h3,
.panel h3 {
  margin-top: 0;
}

.status-value {
  margin: 10px 0 4px;
  font-size: 24px;
  font-weight: 700;
}

.status-meta {
  margin: 0;
  color: #4d5a70;
}

.grid {
  margin-top: 20px;
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 20px;
}

.panel ul {
  margin: 0;
  padding-left: 18px;
  color: #4d5a70;
}

.action-button {
  margin-top: 12px;
  border: 0;
  border-radius: 999px;
  padding: 10px 18px;
  background: #204ecf;
  color: #fff;
  cursor: pointer;
}

@media (max-width: 900px) {
  .hero-card,
  .grid {
    grid-template-columns: 1fr;
  }
}
</style>

