import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import postcssPresetEnv from 'postcss-preset-env';
import tailwindcss from 'tailwindcss';
import autoprefixer from 'autoprefixer';

export default defineConfig({
  plugins: [react()],
  root: '.',
  server: {
    port: 3001,
    strictPort: true,
    open: true,
  },
  css: {
    postcss: {
      plugins: [
        postcssPresetEnv({
          stage: 1,
          features: {
            'nesting-rules': true,
            'custom-properties': true,
            'custom-media-queries': true,
            'media-query-ranges': true,
          },
        }),
        tailwindcss(),
        autoprefixer(),
      ],
    },
  },
  build: {
    outDir: 'dist',
  },
});
