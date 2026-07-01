export interface QuestionOption {
  optionKey: string
  content: string
}

export interface PaperQuestion {
  questionId: number
  stem: string
  questionType: string
  score: number
  partialCreditEnabled: boolean
  options: QuestionOption[]
}

export interface PaperDetail {
  id: number
  title: string
  courseId: number
  totalScore: number
  passScore: number
  durationMinutes: number
  allowRedo: boolean
  maxAttempts: number
  startTime: string | null
  endTime: string | null
  published: boolean
  questions: PaperQuestion[]
}

export interface ExamStart {
  examRecordId: number
  paperId: number
  startTime: string
  endTime: string
}

export interface ExamSubmitAnswer {
  questionId: number
  answer: string | string[] | boolean | null
}

export interface ExamResultQuestion {
  questionId: number
  stem: string
  questionType: string
  fullScore: number
  awardedScore: number | null
  correct: boolean | null
  needsManualReview: boolean
  userAnswer: unknown
  standardAnswer: unknown
  analysis: string | null
  options: QuestionOption[]
}

export interface ExamResult {
  examRecordId: number
  paperId: number
  status: string
  objectiveScore: number | null
  totalScore: number | null
  passed: boolean | null
  pendingReview: boolean
  startTime: string
  submitTime: string | null
  deadlineTime: string | null
  questions: ExamResultQuestion[]
}

export interface WrongQuestionQuery {
  courseId?: number
  status?: string
}

export interface WrongQuestion {
  id: number
  questionId: number
  courseId: number
  chapterId: number | null
  questionType: string
  stem: string
  knowledgePoint: string | null
  status: string
  wrongCount: number
  lastWrongAt: string | null
  standardAnswer: unknown
  analysis: string | null
  options: QuestionOption[]
}
