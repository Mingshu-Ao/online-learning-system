<template>
  <section class="hero-card">
    <div>
      <p class="section-card__eyebrow">Study Room</p>
      <h1 class="hero-title">线上自习室</h1>
      <p class="muted">当前在线状态以 Redis 为准，页面支持自动重连、状态同步和番茄钟展示。</p>
    </div>
    <div class="grid">
      <StatCard label="连接状态" :value="studyRoomStore.socketStatus" />
      <StatCard label="番茄钟" :value="timerLabel" :hint="studyRoomStore.timer.sessionToken || '尚未开始'" />
    </div>
  </section>

  <div class="detail-grid">
    <SectionCard title="房间列表" subtitle="加入房间后会自动打开实时同步。">
      <div v-if="loadingRooms" class="empty-state">房间列表加载中...</div>
      <div v-else class="quiz-list">
        <article v-for="room in studyRoomStore.rooms" :key="room.roomId" class="resource-card">
          <div class="meta-row" style="justify-content: space-between;">
            <strong>{{ room.roomName }}</strong>
            <span class="tag">{{ room.status }}</span>
          </div>
          <p class="muted">在线 {{ room.currentOnlineCount }} / {{ room.capacity }}</p>
          <p class="muted">开放时段 {{ formatDateTime(room.openTime) }} - {{ formatDateTime(room.closeTime) }}</p>
          <button class="primary-button" @click="joinRoom(room.roomId)">加入房间</button>
        </article>
      </div>
    </SectionCard>

    <SectionCard title="房间快照" subtitle="座位、状态和番茄钟都会实时刷新。">
      <template #actions>
        <div class="inline-actions">
          <button class="secondary-button" :disabled="!currentRoomId" @click="changeState('FOCUSING')">专注</button>
          <button class="secondary-button" :disabled="!currentRoomId" @click="changeState('BREAK')">休息</button>
          <button class="secondary-button" :disabled="!currentRoomId" @click="changeState('AWAY')">暂离</button>
          <button class="danger-button" :disabled="!currentRoomId" @click="leaveCurrentRoom">离开房间</button>
        </div>
      </template>

      <div v-if="!studyRoomStore.snapshot" class="empty-state">先选择一个自习室加入。</div>
      <template v-else>
        <div class="grid-3">
          <StatCard label="当前房间" :value="studyRoomStore.snapshot.roomId" />
          <StatCard label="在线人数" :value="studyRoomStore.snapshot.onlineCount" />
          <StatCard label="我的座位" :value="studyRoomStore.currentJoin?.seatNo ?? '--'" />
        </div>
        <SectionCard title="番茄钟控制" subtitle="允许 25 / 45 / 60 分钟。">
          <div class="inline-actions">
            <button class="secondary-button" :disabled="!currentRoomId" @click="startTimer(25)">25 分钟</button>
            <button class="secondary-button" :disabled="!currentRoomId" @click="startTimer(45)">45 分钟</button>
            <button class="secondary-button" :disabled="!currentRoomId" @click="startTimer(60)">60 分钟</button>
            <button class="primary-button" :disabled="!studyRoomStore.timer.sessionToken || !currentRoomId" @click="finishTimer">
              完成当前番茄钟
            </button>
          </div>
        </SectionCard>
        <StudyRoomSeatGrid :seats="studyRoomStore.snapshot.seats" />
      </template>
    </SectionCard>
  </div>
</template>

<script setup lang="ts">
import { computed, onMounted, onUnmounted, ref } from 'vue'
import SectionCard from '@/components/SectionCard.vue'
import StatCard from '@/components/StatCard.vue'
import StudyRoomSeatGrid from '@/components/StudyRoomSeatGrid.vue'
import { fetchStudyRoomSnapshot, fetchStudyRooms, joinStudyRoom, leaveStudyRoom } from '@/api/studyRoomApi'
import { useAppStore } from '@/store/app'
import { useAuthStore } from '@/store/auth'
import { useStudyRoomStore } from '@/store/studyRoom'
import type { StudyRoomSeat, StudyRoomWsEnvelope } from '@/types/studyRoom'
import { formatDateTime, toCountdownLabel } from '@/utils/format'
import { StudyRoomSocketClient } from '@/utils/studyRoomSocket'

const appStore = useAppStore()
const authStore = useAuthStore()
const studyRoomStore = useStudyRoomStore()
const loadingRooms = ref(false)
const nowTick = ref(Date.now())
let socketClient: StudyRoomSocketClient | null = null
let clockTimer: number | null = null

const currentRoomId = computed(() => studyRoomStore.currentJoin?.roomId ?? null)
const timerLabel = computed(() => {
  nowTick.value
  return toCountdownLabel(studyRoomStore.timer.endTime)
})

function updateSeat(seatNo: number, updater: (seat: StudyRoomSeat) => StudyRoomSeat) {
  if (!studyRoomStore.snapshot) {
    return
  }
  studyRoomStore.setSnapshot({
    ...studyRoomStore.snapshot,
    seats: studyRoomStore.snapshot.seats.map((seat) => (seat.seatNo === seatNo ? updater(seat) : seat))
  })
}

function setSocketStatus(status: 'connecting' | 'online' | 'offline') {
  studyRoomStore.setSocketStatus(status)
}

function handleSocketMessage(message: StudyRoomWsEnvelope<Record<string, unknown>>) {
  if (!studyRoomStore.snapshot || message.roomId !== studyRoomStore.snapshot.roomId) {
    return
  }
  const payload = message.payload ?? {}
  if (message.type === 'ROOM_JOIN') {
    const seatNo = Number(payload.seatNo)
    updateSeat(seatNo, (seat) => ({
      ...seat,
      userId: message.senderId,
      nickname: String(payload.nickname ?? '同学'),
      state: String(payload.state ?? 'FOCUSING')
    }))
    studyRoomStore.setSnapshot({
      ...studyRoomStore.snapshot,
      onlineCount: studyRoomStore.snapshot.onlineCount + 1
    })
  }
  if (message.type === 'ROOM_LEAVE') {
    const seatNo = Number(payload.seatNo)
    updateSeat(seatNo, (seat) => ({ ...seat, userId: null, nickname: null, state: null }))
    studyRoomStore.setSnapshot({
      ...studyRoomStore.snapshot,
      onlineCount: Math.max(0, studyRoomStore.snapshot.onlineCount - 1)
    })
  }
  if (message.type === 'ROOM_USER_STATE_CHANGE' || message.type === 'ROOM_RECONNECT') {
    const seatNo = Number(payload.seatNo)
    updateSeat(seatNo, (seat) => ({ ...seat, state: String(payload.state ?? seat.state) }))
  }
  if (message.type === 'ROOM_TIMER_START' && message.senderId === authStore.profile?.id) {
    studyRoomStore.setTimer({
      sessionToken: String(payload.sessionToken ?? ''),
      durationMinutes: Number(payload.durationMinutes ?? 0),
      endTime: payload.endTime ? String(payload.endTime) : null
    })
  }
  if (message.type === 'ROOM_TIMER_FINISH' && message.senderId === authStore.profile?.id) {
    studyRoomStore.resetTimer()
    appStore.setNotice('本次番茄钟已完成并结算。', 'success')
  }
}

function ensureSocket(roomId: number) {
  if (!authStore.token || !authStore.profile) {
    return
  }
  if (!socketClient) {
    socketClient = new StudyRoomSocketClient({
      token: authStore.token,
      roomId,
      senderId: authStore.profile.id,
      onStatusChange: setSocketStatus,
      onMessage: handleSocketMessage
    })
    socketClient.connect()
    return
  }
  socketClient.updateContext(roomId, authStore.profile.id)
}

async function loadRooms() {
  loadingRooms.value = true
  try {
    studyRoomStore.setRooms(await fetchStudyRooms())
  } finally {
    loadingRooms.value = false
  }
}

async function joinRoom(roomId: number) {
  const joinInfo = await joinStudyRoom(roomId)
  studyRoomStore.setCurrentJoin(joinInfo)
  studyRoomStore.setSnapshot(await fetchStudyRoomSnapshot(roomId))
  ensureSocket(roomId)
  appStore.setNotice(`已加入房间 ${roomId}，座位号 ${joinInfo.seatNo}。`, 'success')
}

async function leaveCurrentRoom() {
  if (!currentRoomId.value) {
    return
  }
  await leaveStudyRoom(currentRoomId.value)
  studyRoomStore.setCurrentJoin(null)
  studyRoomStore.setSnapshot(null)
  studyRoomStore.resetTimer()
  socketClient?.disconnect()
  socketClient = null
  appStore.setNotice('已离开自习室。', 'success')
  await loadRooms()
}

function changeState(state: 'FOCUSING' | 'BREAK' | 'AWAY') {
  if (!currentRoomId.value || !socketClient) {
    return
  }
  socketClient.send('ROOM_USER_STATE_CHANGE', { state })
}

function startTimer(durationMinutes: number) {
  if (!currentRoomId.value || !socketClient) {
    return
  }
  socketClient.send('ROOM_TIMER_START', { durationMinutes })
}

function finishTimer() {
  if (!currentRoomId.value || !socketClient || !studyRoomStore.timer.sessionToken) {
    return
  }
  socketClient.send('ROOM_TIMER_FINISH', { sessionToken: studyRoomStore.timer.sessionToken })
}

onMounted(() => {
  loadRooms()
  clockTimer = window.setInterval(() => {
    nowTick.value = Date.now()
  }, 1000)
})

onUnmounted(() => {
  if (clockTimer !== null) {
    window.clearInterval(clockTimer)
  }
  socketClient?.disconnect()
})
</script>
