import http, { unwrapResponse } from '@/api/http'
import type { AiAssistantResponse, AiConversationDetail, AiConversationSummary } from '@/types/ai'

export function askAiQuestion(courseId: number, question: string) {
  return unwrapResponse<AiAssistantResponse>(http.post('/student/ai/ask', { courseId, question }))
}

export function solveAiImage(courseId: number, image: File) {
  const formData = new FormData()
  formData.append('courseId', String(courseId))
  formData.append('image', image)
  return unwrapResponse<AiAssistantResponse>(http.post('/student/ai/solve-image', formData))
}

export function fetchAiConversations() {
  return unwrapResponse<AiConversationSummary[]>(http.get('/student/ai/conversations'))
}

export function fetchAiConversationDetail(conversationId: number) {
  return unwrapResponse<AiConversationDetail>(http.get(`/student/ai/conversations/${conversationId}`))
}
