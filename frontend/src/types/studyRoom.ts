export interface StudyRoomListItem {
  roomId: number
  roomName: string
  capacity: number
  currentOnlineCount: number
  openTime: string
  closeTime: string
  status: string
}

export interface StudyRoomSeat {
  seatNo: number
  userId: number | null
  nickname: string | null
  state: string | null
}

export interface StudyRoomSnapshot {
  roomId: number
  onlineCount: number
  seats: StudyRoomSeat[]
}

export interface StudyRoomJoin {
  roomId: number
  seatNo: number
  state: string
}

export type StudyRoomMessageType =
  | 'ROOM_JOIN'
  | 'ROOM_LEAVE'
  | 'ROOM_USER_STATE_CHANGE'
  | 'ROOM_TIMER_START'
  | 'ROOM_TIMER_FINISH'
  | 'ROOM_HEARTBEAT'
  | 'ROOM_RECONNECT'

export interface StudyRoomWsEnvelope<T = Record<string, unknown> | null> {
  type: StudyRoomMessageType
  roomId: number
  senderId: number
  timestamp: number
  payload: T
}

export interface StudyRoomTimerState {
  sessionToken: string | null
  durationMinutes: number | null
  endTime: string | null
}
