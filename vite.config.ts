import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  // config.ts loads office.config.json with top-level await, which needs an ES2022 target
  build: { target: 'es2022' },
  server: {
    port: 3333,
    proxy: {
      '/ws': {
        target: 'ws://localhost:3334',
        ws: true,
      },
    },
  },
})
