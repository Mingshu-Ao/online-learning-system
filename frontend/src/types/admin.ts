export interface AdminDashboard {
  totalUsers: number
  dailyActiveUsers: number
  totalCourses: number
  todayLearningDurationSeconds: number
  currentStudyRoomOnlineUsers: number
  todayAiCallCount: number
}

export interface AdminDailyStatisticsItem {
  date: string
  newUsers: number
  dailyActiveUsers: number
  aiCallCount: number
  learningDurationSeconds: number
}

export interface AdminStatistics {
  days: number
  items: AdminDailyStatisticsItem[]
}

export interface Announcement {
  id: number
  title: string
  content: string
  visibility: string
  status: string
  publishAt: string | null
  createdAt: string
  updatedAt: string
}

export interface AnnouncementUpsertPayload {
  title: string
  content: string
  visibility: string
  status: string
  publishAt: string | null
}

export interface LoginLog {
  id: number
  userId: number | null
  username: string
  success: boolean
  failureReason: string | null
  requestPath: string
  ipAddress: string | null
  userAgent: string | null
  createdAt: string
}

export interface OperationLog {
  id: number
  operatorUserId: number | null
  operatorUsername: string
  action: string
  targetType: string
  targetId: string | null
  httpMethod: string
  requestPath: string
  success: boolean
  requestSummary: string | null
  errorMessage: string | null
  durationMs: number | null
  ipAddress: string | null
  userAgent: string | null
  createdAt: string
}

export interface ResourceAccessLog {
  id: number
  userId: number | null
  courseId: number | null
  resourceId: number | null
  resourceType: string | null
  requestPath: string
  ipAddress: string | null
  userAgent: string | null
  createdAt: string
}

export interface SystemErrorLog {
  id: number
  userId: number | null
  errorCode: number | null
  exceptionClass: string
  errorMessage: string
  httpMethod: string
  requestPath: string
  requestSummary: string | null
  ipAddress: string | null
  userAgent: string | null
  createdAt: string
}
