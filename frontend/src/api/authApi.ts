import http, { unwrapResponse } from '@/api/http'
import type { LoginRequest, LoginSession, UserProfile } from '@/types/auth'

export function login(payload: LoginRequest) {
  return unwrapResponse<LoginSession>(http.post('/auth/login', payload))
}

export function logout() {
  return unwrapResponse<void>(http.post('/auth/logout'))
}

export function fetchCurrentUserProfile() {
  return unwrapResponse<UserProfile>(http.get('/user/profile'))
}
