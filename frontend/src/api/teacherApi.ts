import http, { unwrapResponse } from '@/api/http'
import type {
  CourseDetail,
  CourseChapter,
  CourseResource,
  TeacherChapterForm,
  TeacherChapterSortItem,
  TeacherCourseForm,
  TeacherResourceForm
} from '@/types/course'

export function createTeacherCourse(payload: TeacherCourseForm) {
  return unwrapResponse<CourseDetail>(http.post('/teacher/courses', payload))
}

export function updateTeacherCourse(courseId: number, payload: TeacherCourseForm) {
  return unwrapResponse<CourseDetail>(http.put(`/teacher/courses/${courseId}`, payload))
}

export function submitTeacherCourseReview(courseId: number) {
  return unwrapResponse<CourseDetail>(http.post(`/teacher/courses/${courseId}/submit-review`))
}

export function createTeacherChapter(courseId: number, payload: TeacherChapterForm) {
  return unwrapResponse<CourseChapter>(http.post(`/teacher/courses/${courseId}/chapters`, payload))
}

export function updateTeacherChapter(chapterId: number, payload: TeacherChapterForm) {
  return unwrapResponse<CourseChapter>(http.put(`/teacher/chapters/${chapterId}`, payload))
}

export function sortTeacherChapters(courseId: number, chapters: TeacherChapterSortItem[]) {
  return unwrapResponse<CourseChapter[]>(http.put(`/teacher/courses/${courseId}/chapters/sort`, { chapters }))
}

export function uploadTeacherResourceMetadata(payload: TeacherResourceForm) {
  return unwrapResponse<CourseResource>(http.post('/teacher/resources/upload', payload))
}
