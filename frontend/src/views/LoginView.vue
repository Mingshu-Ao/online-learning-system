<template>
  <div class="app-shell" style="grid-template-columns: 1fr; min-height: 100vh;">
    <main class="app-frame" style="display: grid; place-items: center; min-height: 100vh;">
      <section class="hero-card" style="max-width: 980px; width: 100%;">
        <div>
          <p class="section-card__eyebrow">Welcome Back</p>
          <h1 class="hero-title">登录在线学习系统</h1>
          <p class="muted">
            统一入口会根据角色自动跳转到学员、教师或管理端页面，Token 由全局状态统一托管。
          </p>
          <div class="grid-3" style="margin-top: 20px;">
            <StatCard label="学习" value="课程 + 视频 + 测验" hint="学生侧主流程" />
            <StatCard label="协作" value="自习室 + AI" hint="实时状态与智能答疑" />
            <StatCard label="运营" value="教师 + 管理端" hint="课程维护与运营看板" />
          </div>
        </div>

        <SectionCard title="账号登录" subtitle="使用已分配账号进入系统。">
          <form class="section-card__body" @submit.prevent="handleLogin">
            <label class="field">
              <span>用户名</span>
              <input v-model.trim="form.username" placeholder="student001 / teacher001 / admin001" />
            </label>
            <label class="field">
              <span>密码</span>
              <input v-model="form.password" type="password" placeholder="请输入密码" />
            </label>
            <p v-if="errorMessage" class="muted" style="color: #a32626;">{{ errorMessage }}</p>
            <button class="primary-button" :disabled="submitting" type="submit">
              {{ submitting ? '登录中...' : '登录并进入系统' }}
            </button>
          </form>
        </SectionCard>
      </section>
    </main>
  </div>
</template>

<script setup lang="ts">
import { reactive, ref } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import SectionCard from '@/components/SectionCard.vue'
import StatCard from '@/components/StatCard.vue'
import { useAppStore } from '@/store/app'
import { useAuthStore } from '@/store/auth'
import { getDefaultRouteForRoles } from '@/utils/route'

const router = useRouter()
const route = useRoute()
const authStore = useAuthStore()
const appStore = useAppStore()

const form = reactive({
  username: '',
  password: ''
})
const submitting = ref(false)
const errorMessage = ref('')

async function handleLogin() {
  if (!form.username || !form.password) {
    errorMessage.value = '请输入用户名和密码。'
    return
  }
  submitting.value = true
  errorMessage.value = ''
  try {
    await authStore.loginWithPassword(form)
    appStore.setNotice('登录成功，正在为你跳转。', 'success')
    const redirect = typeof route.query.redirect === 'string' ? route.query.redirect : ''
    await router.push(redirect || getDefaultRouteForRoles(authStore.roles))
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : '登录失败'
  } finally {
    submitting.value = false
  }
}
</script>
