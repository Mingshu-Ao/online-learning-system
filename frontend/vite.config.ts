import { fileURLToPath, URL } from 'node:url'
import { defineConfig, loadEnv } from 'vite'
import vue from '@vitejs/plugin-vue'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const configuredFrontendPort = Number.parseInt(env.FRONTEND_PORT ?? '5173', 10)
  const frontendPort = Number.isNaN(configuredFrontendPort) ? 5173 : configuredFrontendPort
  const backendPort = env.SERVER_PORT ?? '8080'
  const proxyTarget = env.VITE_DEV_PROXY_TARGET ?? `http://127.0.0.1:${backendPort}`

  return {
    plugins: [vue()],
    resolve: {
      alias: {
        '@': fileURLToPath(new URL('./src', import.meta.url))
      }
    },
    server: {
      host: '0.0.0.0',
      port: frontendPort,
      proxy: {
        '/api': {
          target: proxyTarget,
          changeOrigin: true
        },
        '/ws': {
          target: proxyTarget,
          ws: true,
          changeOrigin: true
        }
      }
    }
  }
})
