import { normalizeRole } from '@/utils/format'

export function getDefaultRouteForRoles(roles: string[]) {
  const normalizedRoles = roles.map(normalizeRole)
  if (normalizedRoles.includes('ADMIN')) {
    return '/admin'
  }
  if (normalizedRoles.includes('TEACHER')) {
    return '/teacher/courses'
  }
  if (normalizedRoles.includes('STUDENT')) {
    return '/courses'
  }
  return '/courses'
}
