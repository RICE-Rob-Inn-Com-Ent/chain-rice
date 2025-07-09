import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3001,
    host: '0.0.0.0',
    open: false,
    fs: {
      allow: [
        path.resolve(__dirname, './'),
      ],
    },
  },
  build: {
    outDir: 'dist'
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src"),
    },
  },
});
