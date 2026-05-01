import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3002,
    host: '0.0.0.0',
    watch: {
      usePolling: true,
      interval: 100,
    },
    hmr: {
      host: 'localhost',
      port: 3002,
      protocol: 'ws',
    },
    allowedHosts: [
      'localhost',
      '127.0.0.1',
      'singalong-dev.nicenature.space',
    ],
  },
  preview: {
    port: 3002,
  },
})

