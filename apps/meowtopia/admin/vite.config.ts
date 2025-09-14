import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

export default defineConfig({
  plugins: [react()],
  cacheDir: '/tmp/vite-admin',
  server: {
    port: 8000,
    host: "0.0.0.0",
    open: false,
    fs: {
      allow: [path.resolve(__dirname, "./")],
    },
    proxy: {
      "/api": {
        target: "http://localhost:5000",
        changeOrigin: true,
        secure: false,
      },
    },
  },
  preview: {
    port: 8000,
    host: "0.0.0.0",
  },
  build: {
    outDir: "dist",
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "src"),
    },
  },
  define: {
    // Make environment variables available to the app
    "process.env.DB_API_URL": JSON.stringify(
      process.env.DB_API_URL || "http://localhost:5000"
    ),
    "process.env.ADMIN_APP_URL": JSON.stringify(
      process.env.ADMIN_APP_URL || "http://localhost:8000"
    ),
    "process.env.GOOGLE_API_KEY": JSON.stringify(
      process.env.GOOGLE_API_KEY || ""
    ),
    "process.env.FACEBOOK_API_KEY": JSON.stringify(
      process.env.FACEBOOK_API_KEY || ""
    ),
  },
});
