import axios from 'axios'
import router from '@/router'
import type { ApiResponse } from '@/types/api'
import { clearStoredToken, getStoredToken } from '@/utils/auth'

const AUTH_FREE_PATHS = new Set(['/auth/login', '/auth/register'])

const http = axios.create({
  baseURL: import.meta.env.VITE_API_BASE_URL ?? '',
  timeout: 8000
})

function shouldAttachToken(url?: string) {
  if (!url) {
    return true
  }
  return !AUTH_FREE_PATHS.has(url)
}

http.interceptors.request.use((config) => {
  const token = getStoredToken()
  if (token && shouldAttachToken(config.url)) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

http.interceptors.response.use(
  (response) => response,
  async (error) => {
    const status = error?.response?.status
    if (status === 401) {
      clearStoredToken()
      if (router.currentRoute.value.name !== 'login') {
        await router.replace({
          name: 'login',
          query: {
            redirect: router.currentRoute.value.fullPath
          }
        })
      }
    }
    return Promise.reject(error)
  }
)

export async function unwrapResponse<T>(request: Promise<{ data: ApiResponse<T> }>): Promise<T> {
  const response = await request
  if (response.data.code !== 0) {
    throw new Error(response.data.message)
  }
  return response.data.data
}

export default http
