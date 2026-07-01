import http, { unwrapResponse } from '@/api/http'
import type { CourseSimple, SystemStatus } from '@/types/system'

export function fetchSystemStatus() {
  return unwrapResponse<SystemStatus>(http.get('/common/ping'))
}

export function fetchPublicCourses() {
  return unwrapResponse<CourseSimple[]>(http.get('/common/courses'))
}

