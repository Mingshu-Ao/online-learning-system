<template>
  <div class="pagination-bar">
    <button class="secondary-button" :disabled="pageNum <= 1" @click="$emit('update:pageNum', pageNum - 1)">
      上一页
    </button>
    <span>第 {{ pageNum }} 页 / 共 {{ totalPages }} 页</span>
    <button class="secondary-button" :disabled="pageNum >= totalPages" @click="$emit('update:pageNum', pageNum + 1)">
      下一页
    </button>
  </div>
</template>

<script setup lang="ts">
import { computed } from 'vue'

const props = defineProps<{
  total: number
  pageNum: number
  pageSize: number
}>()

defineEmits<{
  (event: 'update:pageNum', value: number): void
}>()

const totalPages = computed(() => Math.max(1, Math.ceil(props.total / props.pageSize)))
</script>
