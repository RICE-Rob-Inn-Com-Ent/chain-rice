import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': '/src',
      '@/components': '/src/components',
      '@/styles': '/src/styles',
      '@/utils': '/src/utils',
      '@/hooks': '/src/hooks',
      '@/types': '/src/types',
    },
  },
  server: {
    port: 3000,
    host: '0.0.0.0',
  },
})