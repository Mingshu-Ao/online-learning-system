export interface CourseListQuery {
  pageNum?: number
  pageSize?: number
  keyword?: string
  category?: string
  difficulty?: string
}

export interface CourseListItem {
  id: number
  title: string
  coverUrl: string | null
  teacherName: string
  difficulty: string | null
  studentCount: number
}

export interface CourseResource {
  id: number
  courseId: number
  chapterId: number
  title: string
  resourceType: string
  accessType: string
  fileUrl: string | null
  originalFileName: string | null
  mimeType: string | null
  fileSize: number | null
  durationSeconds: number | null
  transcodingStatus: string | null
  coverUrl: string | null
}

export interface CourseChapter {
  id: number
  courseId: number
  parentId: number | null
  title: string
  sortOrder: number
  resources: CourseResource[]
}

export interface CourseDetail {
  id: number
  title: string
  summary: string | null
  coverUrl: string | null
  category: string | null
  difficulty: string | null
  teacherId: number | null
  teacherName: string | null
  studentCount: number
  status: string
  reviewComment: string | null
  chapters: CourseChapter[]
}

export interface VideoProgressItem {
  resourceId: number
  chapterId: number
  currentPosition: number
  duration: number
  progressPercent: number
  completed: boolean
  lastStudyAt: string | null
}

export interface CourseLearningProgress {
  courseId: number
  totalVideoCount: number
  completedVideoCount: number
  totalDurationSeconds: number
  totalEffectiveStudySeconds: number
  completionPercent: number
  completed: boolean
  resumeResourceId: number | null
  resumeChapterId: number | null
  resumePosition: number | null
  lastStudyAt: string | null
  videos: VideoProgressItem[]
}

export interface LearningCalendarItem {
  date: string
  studySeconds: number
}

export interface LearningStats {
  startDate: string
  endDate: string
  todayStudySeconds: number
  totalStudySeconds: number
  activeDays: number
  consecutiveStudyDays: number
  calendar: LearningCalendarItem[]
}

export interface VideoProgressReport {
  courseId: number
  chapterId: number
  resourceId: number
  currentPosition: number
  duration: number
  playbackRate: number
  clientTimestamp: number
}

export interface ResourceAccessUrl {
  accessUrl: string
}

export interface TeacherCourseForm {
  title: string
  summary: string
  coverUrl: string
  category: string
  difficulty: string
}

export interface TeacherChapterForm {
  parentId: number | null
  title: string
  sortOrder: number
}

export interface TeacherChapterSortItem {
  chapterId: number
  parentId: number | null
  sortOrder: number
}

export interface TeacherResourceForm {
  courseId: number
  chapterId: number
  title: string
  resourceType: string
  accessType: string
  originalFileName: string
  mimeType: string
  fileSize: number
  durationSeconds?: number | null
  coverUrl?: string | null
}
