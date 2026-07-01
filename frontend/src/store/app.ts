import { defineStore } from 'pinia'
import type { NoticeState } from '@/types/common'

export const useAppStore = defineStore('app', {
  state: () => ({
    appName: 'Online Learning System',
    notice: null as NoticeState | null
  }),
  actions: {
    setNotice(message: string, tone: NoticeState['tone'] = 'info') {
      this.notice = { message, tone }
    },
    clearNotice() {
      this.notice = null
    }
  }
})
