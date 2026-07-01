<template>
  <RouterView v-if="route.meta.blank" />
  <div v-else class="app-shell">
    <aside class="sidebar">
      <div>
        <p class="sidebar__eyebrow">Online Learning System</p>
        <h1>学习主控台</h1>
        <p class="sidebar__summary">课程、答题、自习、AI 助教和管理运营都汇总在同一套体验里。</p>
      </div>
      <nav class="sidebar__nav">
        <RouterLink v-for="item in navItems" :key="item.to" :to="item.to">{{ item.label }}</RouterLink>
      </nav>
    </aside>

    <div class="app-frame">
      <header class="topbar">
        <div>
          <p class="topbar__label">{{ route.meta.title || '在线学习系统' }}</p>
          <h2>{{ authStore.isAuthenticated ? `${authStore.displayName}，欢迎回来` : '请先登录以解锁完整能力' }}</h2>
        </div>
        <div class="topbar__actions">
          <span v-if="authStore.profile" class="pill">{{ authStore.roles.map(formatRole).join(' / ') }}</span>
          <RouterLink v-if="!authStore.isAuthenticated" class="primary-button" to="/login">登录</RouterLink>
          <button v-else class="secondary-button" @click="handleLogout">退出</button>
        </div>
      </header>

      <transition name="fade">
        <div v-if="appStore.notice" class="notice-banner" :class="`notice-banner--${appStore.notice.tone}`">
          <span>{{ appStore.notice.message }}</span>
          <button class="ghost-button" @click="appStore.clearNotice">知道了</button>
        </div>
      </transition>

      <main class="app-main">
        <RouterView />
      </main>
    </div>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'
import { RouterLink, RouterView, useRoute, useRouter } from 'vue-router'
import { useAppStore } from '@/store/app'
import { useAuthStore } from '@/store/auth'
import { formatRole } from '@/utils/format'

const route = useRoute()
const router = useRouter()
const appStore = useAppStore()
const authStore = useAuthStore()

const navItems = computed(() => {
  const items = [
    { label: '课程列表', to: '/courses' }
  ]
  if (authStore.hasRole('STUDENT')) {
    items.push(
      { label: '错题本', to: '/wrong-questions' },
      { label: '线上自习室', to: '/study-rooms' },
      { label: 'AI 助教', to: '/ai-assistant' }
    )
  }
  if (authStore.hasRole('TEACHER')) {
    items.push({ label: '教师课程管理', to: '/teacher/courses' })
  }
  if (authStore.hasRole('ADMIN')) {
    items.push({ label: '管理端', to: '/admin' })
  }
  return items
})

async function handleLogout() {
  await authStore.logoutSession()
  appStore.setNotice('已安全退出登录。', 'success')
  await router.push('/courses')
}
</script>
