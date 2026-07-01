import http, { unwrapResponse } from '@/api/http'
import type { StudyRoomJoin, StudyRoomListItem, StudyRoomSnapshot } from '@/types/studyRoom'

export function fetchStudyRooms() {
  return unwrapResponse<StudyRoomListItem[]>(http.get('/study-rooms'))
}

export function joinStudyRoom(roomId: number) {
  return unwrapResponse<StudyRoomJoin>(http.post(`/study-rooms/${roomId}/join`))
}

export function leaveStudyRoom(roomId: number) {
  return unwrapResponse<void>(http.post(`/study-rooms/${roomId}/leave`))
}

export function fetchStudyRoomSnapshot(roomId: number) {
  return unwrapResponse<StudyRoomSnapshot>(http.get(`/study-rooms/${roomId}/snapshot`))
}
