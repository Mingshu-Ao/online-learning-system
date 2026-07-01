<template>
  <div class="seat-grid">
    <article
      v-for="seat in seats"
      :key="seat.seatNo"
      class="seat-tile"
      :class="seat.state ? `seat-tile--${seat.state.toLowerCase()}` : ''"
    >
      <p class="seat-tile__no">座位 {{ seat.seatNo }}</p>
      <strong>{{ seat.nickname || '空闲' }}</strong>
      <p>{{ seat.state || 'AVAILABLE' }}</p>
    </article>
  </div>
</template>

<script setup lang="ts">
import type { StudyRoomSeat } from '@/types/studyRoom'

defineProps<{
  seats: StudyRoomSeat[]
}>()
</script>
