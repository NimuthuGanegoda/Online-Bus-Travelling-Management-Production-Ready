import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: true,
    proxy: {
      '/api': {
        target: 'http://100.95.76.97:5000',
        changeOrigin: true,
        headers: {
          'Origin': 'http://localhost:3000',
          'Referer': 'http://localhost:3000/',
        },
      },
      '/health': {
        target: 'http://100.95.76.97:5000',
        changeOrigin: true,
        headers: {
          'Origin': 'http://localhost:3000',
          'Referer': 'http://localhost:3000/',
        },
      }
    }
  }
})
