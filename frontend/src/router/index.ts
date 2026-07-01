import { createRouter, createWebHistory, type RouteRecordRaw } from 'vue-router'
import { useAppStore } from '@/store/app'
import { useAuthStore } from '@/store/auth'
import { getDefaultRouteForRoles } from '@/utils/route'

declare module 'vue-router' {
  interface RouteMeta {
    title?: string
    requiresAuth?: boolean
    roles?: string[]
    blank?: boolean
  }
}

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    redirect: '/courses'
  },
  {
    path: '/login',
    name: 'login',
    component: () => import('@/views/LoginView.vue'),
    meta: {
      title: '登录',
      blank: true
    }
  },
  {
    path: '/courses',
    name: 'courses',
    component: () => import('@/views/CourseListView.vue'),
    meta: {
      title: '课程列表'
    }
  },
  {
    path: '/courses/:courseId',
    name: 'course-detail',
    component: () => import('@/views/CourseDetailView.vue'),
    meta: {
      title: '课程详情'
    }
  },
  {
    path: '/learn/:courseId/:resourceId',
    name: 'video-learning',
    component: () => import('@/views/VideoLearningView.vue'),
    meta: {
      title: '视频学习',
      requiresAuth: true,
      roles: ['STUDENT']
    }
  },
  {
    path: '/quiz/:paperId',
    name: 'quiz-exam',
    component: () => import('@/views/QuizExamView.vue'),
    meta: {
      title: '测验答题',
      requiresAuth: true,
      roles: ['STUDENT']
    }
  },
  {
    path: '/wrong-questions',
    name: 'wrong-questions',
    component: () => import('@/views/WrongQuestionsView.vue'),
    meta: {
      title: '错题本',
      requiresAuth: true,
      roles: ['STUDENT']
    }
  },
  {
    path: '/study-rooms',
    name: 'study-rooms',
    component: () => import('@/views/StudyRoomView.vue'),
    meta: {
      title: '线上自习室',
      requiresAuth: true,
      roles: ['STUDENT']
    }
  },
  {
    path: '/ai-assistant',
    name: 'ai-assistant',
    component: () => import('@/views/AiAssistantView.vue'),
    meta: {
      title: 'AI 助教',
      requiresAuth: true,
      roles: ['STUDENT']
    }
  },
  {
    path: '/teacher/courses',
    name: 'teacher-courses',
    component: () => import('@/views/TeacherCourseManageView.vue'),
    meta: {
      title: '教师课程管理',
      requiresAuth: true,
      roles: ['TEACHER']
    }
  },
  {
    path: '/admin',
    name: 'admin-dashboard',
    component: () => import('@/views/AdminDashboardView.vue'),
    meta: {
      title: '管理端',
      requiresAuth: true,
      roles: ['ADMIN']
    }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach(async (to) => {
  if (to.meta.title) {
    document.title = `${to.meta.title} - 在线学习系统`
  }

  const authStore = useAuthStore()
  const appStore = useAppStore()
  authStore.hydrate()

  if (authStore.token && !authStore.profileLoaded) {
    try {
      await authStore.ensureProfile()
    } catch (error) {
      appStore.setNotice(error instanceof Error ? error.message : '登录状态已失效', 'error')
    }
  }

  if (to.name === 'login' && authStore.isAuthenticated) {
    return getDefaultRouteForRoles(authStore.roles)
  }

  if (!to.meta.requiresAuth) {
    return true
  }

  if (!authStore.isAuthenticated) {
    appStore.setNotice('请先登录后再访问该页面。', 'warning')
    return {
      name: 'login',
      query: {
        redirect: to.fullPath
      }
    }
  }

  const requiredRoles = to.meta.roles ?? []
  if (requiredRoles.length > 0 && !requiredRoles.some((role) => authStore.hasRole(role))) {
    appStore.setNotice('当前账号没有访问该页面的权限。', 'error')
    return getDefaultRouteForRoles(authStore.roles)
  }

  return true
})

export default router
