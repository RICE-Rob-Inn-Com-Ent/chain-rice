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
  define: {
    // Make environment variables available to the app
    'process.env.REACT_APP_API_URL': JSON.stringify(process.env.REACT_APP_API_URL || 'http://localhost:8000'),
    'process.env.REACT_APP_BASE_URL': JSON.stringify(process.env.REACT_APP_BASE_URL || 'http://localhost:3001'),
    'process.env.REACT_APP_GOOGLE_CLIENT_ID': JSON.stringify(process.env.REACT_APP_GOOGLE_CLIENT_ID || ''),
    'process.env.REACT_APP_FACEBOOK_CLIENT_ID': JSON.stringify(process.env.REACT_APP_FACEBOOK_CLIENT_ID || ''),
    'process.env.REACT_APP_GITHUB_CLIENT_ID': JSON.stringify(process.env.REACT_APP_GITHUB_CLIENT_ID || ''),
  },
});
