import { computed, ref } from 'vue'
import { defineStore } from 'pinia'
import { fetchCurrentUserProfile, login, logout } from '@/api/authApi'
import type { LoginRequest, LoginSession, UserProfile } from '@/types/auth'
import { clearStoredToken, getStoredToken, setStoredToken } from '@/utils/auth'
import { normalizeRole } from '@/utils/format'

export const useAuthStore = defineStore('auth', () => {
  const token = ref('')
  const profile = ref<UserProfile | null>(null)
  const profileLoaded = ref(false)
  const profilePromise = ref<Promise<UserProfile | null> | null>(null)

  const roles = computed(() => (profile.value?.roles ?? []).map(normalizeRole))
  const displayName = computed(() => profile.value?.nickname || profile.value?.username || '访客')
  const isAuthenticated = computed(() => Boolean(token.value))

  function hydrate() {
    if (!token.value) {
      token.value = getStoredToken()
    }
  }

  function applySession(session: LoginSession) {
    token.value = session.token
    setStoredToken(session.token)
  }

  async function loginWithPassword(payload: LoginRequest) {
    const session = await login(payload)
    applySession(session)
    await ensureProfile(true)
    return session
  }

  async function ensureProfile(force = false) {
    if (!token.value) {
      return null
    }
    if (!force && profileLoaded.value && profile.value) {
      return profile.value
    }
    if (!force && profilePromise.value) {
      return profilePromise.value
    }
    const request = fetchCurrentUserProfile()
      .then((result) => {
        profile.value = result
        profileLoaded.value = true
        return result
      })
      .catch((error) => {
        clearSession()
        throw error
      })
      .finally(() => {
        profilePromise.value = null
      })
    profilePromise.value = request
    return request
  }

  async function logoutSession() {
    try {
      if (token.value) {
        await logout()
      }
    } finally {
      clearSession()
    }
  }

  function clearSession() {
    clearStoredToken()
    token.value = ''
    profile.value = null
    profileLoaded.value = false
    profilePromise.value = null
  }

  function hasRole(role: string) {
    return roles.value.includes(normalizeRole(role))
  }

  return {
    token,
    profile,
    profileLoaded,
    roles,
    displayName,
    isAuthenticated,
    hydrate,
    loginWithPassword,
    ensureProfile,
    logoutSession,
    clearSession,
    hasRole
  }
})
