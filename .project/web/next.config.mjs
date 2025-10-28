import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  compress: true,
  transpilePackages: ["@rice-mono/ui-kit"],
  experimental: {
    // allow importing files from outside the project directory
    externalDir: true,
    // try to reduce bundle size for common packages
    optimizePackageImports: ["lucide-react"],
  },
  webpack: (config) => {
    config.resolve.alias = {
      ...config.resolve.alias,
      "@rice-mono/ui-kit": path.resolve(__dirname, "../../.frontend/web"),
    };
    // Ensure webpack resolves index files
    config.resolve.extensions = [".tsx", ".ts", ".jsx", ".js", ".json", ...(config.resolve.extensions || [])];
    return config;
  },
  images: {
    // allow placeholder domains if we add images later
    remotePatterns: [
      { protocol: "https", hostname: "**" },
      { protocol: "http", hostname: "**" },
    ],
  },
  output: "standalone",
  async headers() {
    return [
      {
        source: "/:all*",
        headers: [
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "X-Frame-Options", value: "SAMEORIGIN" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=(self)" },
        ],
      },
      {
        source: "/_next/static/:path*",
        headers: [{ key: "Cache-Control", value: "public, max-age=31536000, immutable" }],
      },
      {
        source: "/static/:path*",
        headers: [{ key: "Cache-Control", value: "public, max-age=31536000, immutable" }],
      },
    ];
  },
};

export default nextConfig;
