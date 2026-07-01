export function formatDateTime(value?: string | null) {
  if (!value) {
    return '未提供'
  }
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return value
  }
  return new Intl.DateTimeFormat('zh-CN', {
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit'
  }).format(date)
}

export function formatFullDateTime(value?: string | null) {
  if (!value) {
    return '未提供'
  }
  const date = new Date(value)
  if (Number.isNaN(date.getTime())) {
    return value
  }
  return new Intl.DateTimeFormat('zh-CN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit'
  }).format(date)
}

export function formatDuration(totalSeconds?: number | null) {
  const seconds = Math.max(0, totalSeconds ?? 0)
  const hours = Math.floor(seconds / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  const remainSeconds = seconds % 60
  if (hours > 0) {
    return `${hours}h ${minutes}m`
  }
  if (minutes > 0) {
    return `${minutes}m ${remainSeconds}s`
  }
  return `${remainSeconds}s`
}

export function normalizeRole(role: string) {
  return role.toUpperCase()
}

export function formatRole(role: string) {
  const normalized = normalizeRole(role)
  if (normalized === 'ADMIN') {
    return '管理员'
  }
  if (normalized === 'TEACHER') {
    return '教师'
  }
  if (normalized === 'STUDENT') {
    return '学员'
  }
  return normalized
}

export function formatPercent(value?: number | null) {
  return `${(value ?? 0).toFixed(1)}%`
}

export function formatFileSize(bytes?: number | null) {
  const value = bytes ?? 0
  if (value >= 1024 * 1024) {
    return `${(value / 1024 / 1024).toFixed(1)} MB`
  }
  if (value >= 1024) {
    return `${(value / 1024).toFixed(1)} KB`
  }
  return `${value} B`
}

export function toCountdownLabel(endTime?: string | null) {
  if (!endTime) {
    return '未启动'
  }
  const distance = new Date(endTime).getTime() - Date.now()
  if (distance <= 0) {
    return '已结束'
  }
  const totalSeconds = Math.floor(distance / 1000)
  const minutes = Math.floor(totalSeconds / 60)
  const seconds = totalSeconds % 60
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`
}
