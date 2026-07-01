import http, { unwrapResponse } from '@/api/http'
import type { PageResult } from '@/types/common'
import type { CourseChapter, CourseDetail, CourseListItem, CourseListQuery, ResourceAccessUrl } from '@/types/course'

export function fetchCourseList(params: CourseListQuery) {
  return unwrapResponse<PageResult<CourseListItem>>(http.get('/courses', { params }))
}

export function fetchCourseDetail(courseId: number) {
  return unwrapResponse<CourseDetail>(http.get(`/courses/${courseId}`))
}

export function fetchCourseChapters(courseId: number) {
  return unwrapResponse<CourseChapter[]>(http.get(`/courses/${courseId}/chapters`))
}

export function fetchResourceAccessUrl(resourceId: number) {
  return unwrapResponse<ResourceAccessUrl>(http.get(`/resources/${resourceId}/access-url`))
}
