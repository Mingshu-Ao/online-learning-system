<template>
  <section class="section-card">
    <header v-if="title || subtitle || $slots.actions" class="section-card__header">
      <div>
        <p v-if="eyebrow" class="section-card__eyebrow">{{ eyebrow }}</p>
        <h2 v-if="title">{{ title }}</h2>
        <p v-if="subtitle" class="section-card__subtitle">{{ subtitle }}</p>
      </div>
      <div v-if="$slots.actions" class="section-card__actions">
        <slot name="actions" />
      </div>
    </header>
    <div class="section-card__body">
      <slot />
    </div>
  </section>
</template>

<script setup lang="ts">
defineProps<{
  title?: string
  subtitle?: string
  eyebrow?: string
}>()
</script>
