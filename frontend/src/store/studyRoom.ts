import { defineStore } from 'pinia'
import type { StudyRoomJoin, StudyRoomListItem, StudyRoomSnapshot, StudyRoomTimerState } from '@/types/studyRoom'

export const useStudyRoomStore = defineStore('studyRoom', {
  state: () => ({
    rooms: [] as StudyRoomListItem[],
    snapshot: null as StudyRoomSnapshot | null,
    currentJoin: null as StudyRoomJoin | null,
    timer: {
      sessionToken: null,
      durationMinutes: null,
      endTime: null
    } as StudyRoomTimerState,
    socketStatus: 'offline' as 'offline' | 'connecting' | 'online'
  }),
  actions: {
    setRooms(rooms: StudyRoomListItem[]) {
      this.rooms = rooms
    },
    setSnapshot(snapshot: StudyRoomSnapshot | null) {
      this.snapshot = snapshot
    },
    setCurrentJoin(join: StudyRoomJoin | null) {
      this.currentJoin = join
    },
    setSocketStatus(status: 'offline' | 'connecting' | 'online') {
      this.socketStatus = status
    },
    setTimer(timer: Partial<StudyRoomTimerState>) {
      this.timer = {
        ...this.timer,
        ...timer
      }
    },
    resetTimer() {
      this.timer = {
        sessionToken: null,
        durationMinutes: null,
        endTime: null
      }
    }
  }
})
