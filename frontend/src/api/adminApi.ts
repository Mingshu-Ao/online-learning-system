import http, { unwrapResponse } from '@/api/http'
import type {
  AdminDashboard,
  AdminStatistics,
  Announcement,
  AnnouncementUpsertPayload,
  LoginLog,
  OperationLog,
  ResourceAccessLog,
  SystemErrorLog
} from '@/types/admin'
import type { PageResult } from '@/types/common'

export function fetchAdminDashboard() {
  return unwrapResponse<AdminDashboard>(http.get('/admin/dashboard'))
}

export function fetchAdminStatistics(days = 7) {
  return unwrapResponse<AdminStatistics>(http.get('/admin/statistics', { params: { days } }))
}

export function fetchAnnouncements(params: Record<string, unknown>) {
  return unwrapResponse<PageResult<Announcement>>(http.get('/admin/announcements', { params }))
}

export function createAnnouncement(payload: AnnouncementUpsertPayload) {
  return unwrapResponse<Announcement>(http.post('/admin/announcements', payload))
}

export function updateAnnouncement(id: number, payload: AnnouncementUpsertPayload) {
  return unwrapResponse<Announcement>(http.put(`/admin/announcements/${id}`, payload))
}

export function deleteAnnouncement(id: number) {
  return unwrapResponse<void>(http.delete(`/admin/announcements/${id}`))
}

export function fetchLoginLogs(params: Record<string, unknown>) {
  return unwrapResponse<PageResult<LoginLog>>(http.get('/admin/logs/login', { params }))
}

export function fetchOperationLogs(params: Record<string, unknown>) {
  return unwrapResponse<PageResult<OperationLog>>(http.get('/admin/logs/operation', { params }))
}

export function fetchResourceAccessLogs(params: Record<string, unknown>) {
  return unwrapResponse<PageResult<ResourceAccessLog>>(http.get('/admin/logs/resource-access', { params }))
}

export function fetchErrorLogs(params: Record<string, unknown>) {
  return unwrapResponse<PageResult<SystemErrorLog>>(http.get('/admin/logs/errors', { params }))
}
