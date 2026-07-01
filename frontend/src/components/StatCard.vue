<template>
  <article class="stat-card">
    <p class="stat-card__label">{{ label }}</p>
    <strong class="stat-card__value">{{ value }}</strong>
    <p v-if="hint" class="stat-card__hint">{{ hint }}</p>
  </article>
</template>

<script setup lang="ts">
defineProps<{
  label: string
  value: string | number
  hint?: string
}>()
</script>
