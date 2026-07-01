export interface PageResult<T> {
  total: number
  records: T[]
}

export interface ListQuery {
  pageNum?: number
  pageSize?: number
}

export interface NoticeState {
  message: string
  tone: 'info' | 'success' | 'warning' | 'error'
}
