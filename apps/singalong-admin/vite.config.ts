import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// Use /admin/ for production builds, / for development
const base = process.env.NODE_ENV === 'production' ? '/admin/' : '/'

// For dev, proxy /api to the gateway (8080) or Node service (5002)
// If running dev locally, use gateway on localhost:8080 (/api/* routes to node)
const apiTarget = process.env.API_URL || 'http://localhost:8080'

// https://vite.dev/config/
export default defineConfig({
  base,
  plugins: [react()],
  server: {
    port: 3001,
    strictPort: false,
    host: '0.0.0.0',
    proxy: {
      '/api': {
        target: apiTarget,
        changeOrigin: true,
        rewrite: (path) => path, // Keep /api prefix
      },
    },
    watch: {
      usePolling: true,
      interval: 100,
    },
    hmr: {
      host: process.env.HMR_HOST || 'localhost',
      port: 3001,
      protocol: 'ws',
    },
    allowedHosts: [
      'localhost',
      '127.0.0.1',
      'thursday.local',
      'singalongadmin-dev.nicenature.space',
      'singalong-admin',
      '0.0.0.0',
    ],
  },
})
