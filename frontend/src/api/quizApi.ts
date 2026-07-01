import http, { unwrapResponse } from '@/api/http'
import type { ExamResult, ExamStart, ExamSubmitAnswer, PaperDetail, WrongQuestion, WrongQuestionQuery } from '@/types/quiz'

export function fetchPaperDetail(paperId: number) {
  return unwrapResponse<PaperDetail>(http.get(`/student/papers/${paperId}`))
}

export function startExam(paperId: number) {
  return unwrapResponse<ExamStart>(http.post(`/student/exams/${paperId}/start`))
}

export function submitExam(examRecordId: number, answers: ExamSubmitAnswer[]) {
  return unwrapResponse<ExamResult>(http.post(`/student/exams/${examRecordId}/submit`, { answers }))
}

export function fetchExamResult(examRecordId: number) {
  return unwrapResponse<ExamResult>(http.get(`/student/exams/${examRecordId}/result`))
}

export function fetchWrongQuestions(params: WrongQuestionQuery) {
  return unwrapResponse<WrongQuestion[]>(http.get('/student/wrong-questions', { params }))
}

export function redoWrongQuestion(id: number) {
  return unwrapResponse<WrongQuestion>(http.post(`/student/wrong-questions/${id}/redo`))
}

export function markWrongQuestionMastered(id: number) {
  return unwrapResponse<WrongQuestion>(http.put(`/student/wrong-questions/${id}/mastered`))
}
