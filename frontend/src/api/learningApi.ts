import http, { unwrapResponse } from '@/api/http'
import type { CourseLearningProgress, LearningStats, VideoProgressReport } from '@/types/course'

export function reportVideoProgress(payload: VideoProgressReport) {
  return unwrapResponse<{ progressPercent: number; completed: boolean }>(http.post('/student/video-progress', payload))
}

export function fetchCourseProgress(courseId: number) {
  return unwrapResponse<CourseLearningProgress>(http.get(`/student/courses/${courseId}/progress`))
}

export function fetchLearningStats() {
  return unwrapResponse<LearningStats>(http.get('/student/learning-stats'))
}
