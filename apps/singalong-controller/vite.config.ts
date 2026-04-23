import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    port: 3002,
    host: '0.0.0.0',
    hmr: {
      protocol: 'https',
      host: 'singalong-dev.nicenature.space',
      port: 443,
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

