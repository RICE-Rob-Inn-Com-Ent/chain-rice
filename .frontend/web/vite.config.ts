import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import postcssPresetEnv from "postcss-preset-env";
import tailwindcss from "tailwindcss";
import autoprefixer from "autoprefixer";
import { resolve } from "node:path";

export default defineConfig({
  plugins: [react()],
  root: ".",
  publicDir: "public",
  server: {
    port: 3001,
    strictPort: false,
    host: "0.0.0.0",
    open: true,
    proxy: {
      "/api/ollama": {
        target: "http://localhost:11434",
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/api\/ollama/, ""),
        configure: (proxy, _options) => {
          proxy.on("error", (err, _req, _res) => {
            console.log("Ollama proxy error:", err);
          });
        },
      },
    },
  },
  resolve: {
    alias: {
      "@": "/home/mrDinkelman/rice-mono/.frontend/web",
    },
  },
  css: {
    postcss: {
      plugins: [
        postcssPresetEnv({
          stage: 1,
          features: {
            "nesting-rules": true,
            "custom-properties": true,
            "custom-media-queries": true,
            "media-query-ranges": true,
          },
        }),
        tailwindcss(),
        autoprefixer(),
      ],
    },
  },
  build: {
    outDir: "dist",
    rollupOptions: {
      input: {
        main: resolve(__dirname, "index.html"),
        thoth: resolve(__dirname, "demo/thoth.html"),
        ra: resolve(__dirname, "demo/ra.html"),
        isis: resolve(__dirname, "demo/isis.html"),
        bastet: resolve(__dirname, "demo/bastet.html"),
        maat: resolve(__dirname, "demo/maat.html"),
        khnum: resolve(__dirname, "demo/khnum.html"),
      },
    },
  },
});
