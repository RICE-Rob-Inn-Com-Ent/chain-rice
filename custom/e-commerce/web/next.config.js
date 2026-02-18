// Minimal Next.js config for meowtopia project
/** @type {import('next').NextConfig} */
const nextConfig = {
  reactStrictMode: true,
  poweredByHeader: false,
  compress: true,
  swcMinify: true,
  // Production optimizations
  productionBrowserSourceMaps: false,
  typescript: {
    ignoreBuildErrors: false,
  },
  // Transpile packages that may not be compatible with Next.js
  transpilePackages: ['@iconify/react'],
  images: {
    remotePatterns: [],
    unoptimized: false,
  },
  // Optimize font loading to prevent preload warnings
  optimizeFonts: true,
  webpack: (config, { dev, isServer }) => {
    // Enable hot reload in development - polling for Docker/WSL
    if (dev) {
      config.watchOptions = {
        poll: 1000,
        aggregateTimeout: 200,
        ignored: ['**/node_modules', '**/.git', '**/.next', '**/prisma/migrate-to-both-dbs.ts', '**/prisma/init-both-dbs.ts'],
      };
      // Use filesystem cache but invalidate on changes
      if (config.cache) {
        config.cache = {
          ...config.cache,
          buildDependencies: {
            config: [__filename],
          },
        };
      }
    }
    
    // Ensure webpack resolves index files
    config.resolve.extensions = [".tsx", ".ts", ".jsx", ".js", ".json", ...(config.resolve.extensions || [])];
    
    // Fix module resolution for @iconify/react
    // Only add alias if module exists to prevent crashes
    try {
      const iconifyPath = require.resolve('@iconify/react');
      config.resolve.alias = {
        ...config.resolve.alias,
        '@iconify/react': iconifyPath,
      };
    } catch (e) {
      // Module not found - skip alias, webpack will handle it normally
      console.warn('@iconify/react not found, skipping alias');
    }
    
    // Fix React module resolution issues
    if (!isServer) {
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
      };
    }
    
    // Fix chunk loading issues
    config.optimization = {
      ...config.optimization,
      splitChunks: {
        chunks: 'all',
        cacheGroups: {
          default: false,
          vendors: false,
        },
      },
    };
    
    return config;
  },
  // Project-specific overrides can be added here
};

module.exports = nextConfig;

