import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

export default defineConfig({
  plugins: [react()],
  root: ".",
  publicDir: "public",
  server: {
    port: 3002,
    strictPort: false,
    host: "0.0.0.0",
    open: true,
  },
  resolve: {
    alias: {
      "@rice-mono/ui-kit": resolve(__dirname, "../web/lib"),
      "@": resolve(__dirname, "./src"),
    },
  },
  build: {
    outDir: "dist",
  },
});

