import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  base: '/admin/',
  plugins: [react()],
  server: {
    port: 3001,
    strictPort: false,
    host: '0.0.0.0',
    watch: {
      usePolling: true,
      interval: 100,
    },
    hmr: {
      host: 'localhost',
      port: 3001,
      protocol: 'ws',
      path: '/admin/__vite_ping',
    },
    allowedHosts: [
      'localhost',
      '127.0.0.1',
      'singalongadmin-dev.nicenature.space',
      'singalong-admin',
      '0.0.0.0',
    ],
  },
})



