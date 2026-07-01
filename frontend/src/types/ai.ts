export interface AiRecommendation {
  type: string
  resourceId: number | null
  reason: string
}

export interface AiAssistantResponse {
  conversationId: number
  questionText: string
  knowledgePoints: string[]
  difficulty: string | null
  solutionSteps: string[]
  mistakeAnalysis: string | null
  recommendations: AiRecommendation[]
  degraded: boolean
  message: string
}

export interface AiConversationSummary {
  conversationId: number
  courseId: number
  inputType: string
  title: string
  latestSummary: string | null
  lastMessageAt: string | null
}

export interface AiConversationMessage {
  messageId: number
  role: string
  inputType: string
  content: string
  fileName: string | null
  mimeType: string | null
  fileSize: number | null
  createdAt: string | null
  structuredResponse: AiAssistantResponse | null
}

export interface AiConversationDetail extends AiConversationSummary {
  messages: AiConversationMessage[]
}
