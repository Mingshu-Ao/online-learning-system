import type { StudyRoomMessageType, StudyRoomWsEnvelope } from '@/types/studyRoom'

interface SocketClientOptions {
  token: string
  roomId: number
  senderId: number
  onStatusChange?: (status: 'connecting' | 'online' | 'offline') => void
  onMessage?: (message: StudyRoomWsEnvelope<Record<string, unknown>>) => void
}

export class StudyRoomSocketClient {
  private socket: WebSocket | null = null
  private reconnectTimer: number | null = null
  private heartbeatTimer: number | null = null
  private reconnectAttempt = 0
  private closedManually = false

  constructor(private options: SocketClientOptions) {}

  connect() {
    this.closedManually = false
    this.updateStatus('connecting')
    const url = this.buildUrl()
    this.socket = new WebSocket(url)
    this.socket.onopen = () => {
      this.reconnectAttempt = 0
      this.updateStatus('online')
      this.startHeartbeat()
      this.send('ROOM_RECONNECT', {})
    }
    this.socket.onmessage = (event) => {
      try {
        const message = JSON.parse(event.data) as StudyRoomWsEnvelope<Record<string, unknown>>
        this.options.onMessage?.(message)
      } catch {
        // Ignore malformed messages and let the server remain the source of truth.
      }
    }
    this.socket.onclose = () => {
      this.stopHeartbeat()
      this.socket = null
      this.updateStatus('offline')
      if (!this.closedManually) {
        this.scheduleReconnect()
      }
    }
    this.socket.onerror = () => {
      this.updateStatus('offline')
    }
  }

  disconnect() {
    this.closedManually = true
    this.stopHeartbeat()
    if (this.reconnectTimer !== null) {
      window.clearTimeout(this.reconnectTimer)
      this.reconnectTimer = null
    }
    this.socket?.close()
    this.socket = null
    this.updateStatus('offline')
  }

  updateContext(roomId: number, senderId: number) {
    this.options = {
      ...this.options,
      roomId,
      senderId
    }
  }

  send(type: StudyRoomMessageType, payload: Record<string, unknown>) {
    if (!this.socket || this.socket.readyState !== WebSocket.OPEN) {
      return
    }
    const envelope: StudyRoomWsEnvelope<Record<string, unknown>> = {
      type,
      roomId: this.options.roomId,
      senderId: this.options.senderId,
      timestamp: Date.now(),
      payload
    }
    this.socket.send(JSON.stringify(envelope))
  }

  private buildUrl() {
    const baseUrl = import.meta.env.VITE_WS_BASE_URL
      ? import.meta.env.VITE_WS_BASE_URL
      : window.location.origin.replace(/^http/, 'ws')
    const normalized = baseUrl.replace(/\/$/, '')
    return `${normalized}/ws?token=${encodeURIComponent(this.options.token)}`
  }

  private startHeartbeat() {
    this.stopHeartbeat()
    this.heartbeatTimer = window.setInterval(() => {
      this.send('ROOM_HEARTBEAT', {})
    }, 20000)
  }

  private stopHeartbeat() {
    if (this.heartbeatTimer !== null) {
      window.clearInterval(this.heartbeatTimer)
      this.heartbeatTimer = null
    }
  }

  private scheduleReconnect() {
    if (this.reconnectTimer !== null) {
      return
    }
    const delay = Math.min(10000, 1000 * 2 ** this.reconnectAttempt)
    this.reconnectAttempt += 1
    this.reconnectTimer = window.setTimeout(() => {
      this.reconnectTimer = null
      this.connect()
    }, delay)
  }

  private updateStatus(status: 'connecting' | 'online' | 'offline') {
    this.options.onStatusChange?.(status)
  }
}
