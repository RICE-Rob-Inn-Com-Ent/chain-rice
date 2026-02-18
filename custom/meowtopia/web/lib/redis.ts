import Redis from "ioredis";

const globalForRedis = globalThis as unknown as {
  redis: Redis | undefined;
};

function getRedisConfig() {
  // Parse REDIS_URL if provided, but prefer individual components
  let host = process.env.REDIS_HOST;
  let port = process.env.REDIS_PORT ? parseInt(process.env.REDIS_PORT, 10) : undefined;
  let password = process.env.REDIS_PASSWORD || undefined;
  let db = process.env.REDIS_DB ? parseInt(process.env.REDIS_DB, 10) : 0;

  // If REDIS_URL is provided and individual components are not, parse URL
  if (process.env.REDIS_URL && !host) {
    try {
      const url = new URL(process.env.REDIS_URL);
      host = host || url.hostname;
      port = port || (url.port ? parseInt(url.port, 10) : 6379);
      password = password || (url.password || undefined);
      db = db || (url.pathname ? parseInt(url.pathname.slice(1), 10) : 0);
    } catch (error) {
      console.warn("⚠️  Failed to parse REDIS_URL, using defaults:", error);
    }
  }

  // Use defaults if not set
  host = host || "devcontainer-redis";
  port = port || 6379;
  db = db || 0;

  return {
    host,
    port,
    password,
    db,
    retryStrategy: (times: number) => {
      const delay = Math.min(times * 50, 2000);
      return delay;
    },
    maxRetriesPerRequest: 3,
    lazyConnect: false, // Connect immediately
    enableReadyCheck: true,
    enableOfflineQueue: false, // Don't queue commands when disconnected
  };
}

// Create Redis client with proper error handling
const redisConfig = getRedisConfig();

// Create Redis instance with lazyConnect to set up event handlers first
const createRedisClient = () => {
  const client = new Redis({
    ...redisConfig,
    lazyConnect: true, // Don't connect immediately - set up handlers first
  });

  // Handle Redis connection events BEFORE connecting
  if (typeof window === "undefined") {
    client.on("connect", () => {
      console.log("✅ Redis connecting...");
    });

    client.on("ready", () => {
      console.log("✅ Redis connected and ready");
    });

    client.on("error", (error) => {
      // Only log if not already connected (to avoid spam)
      if (client.status !== "ready" && client.status !== "connecting") {
        console.warn("⚠️  Redis connection error (non-critical):", error.message);
      }
    });

    client.on("close", () => {
      console.warn("⚠️  Redis connection closed");
    });

    client.on("reconnecting", () => {
      console.log("🔄 Redis reconnecting...");
    });

    // Connect after handlers are set up
    if (process.env.NODE_ENV === "development") {
      setImmediate(async () => {
        try {
          await client.connect();
          await client.ping();
          console.log("✅ Redis connection verified");
        } catch (error: any) {
          console.warn("⚠️  Redis connection error (non-critical):", error.message);
          // Don't throw - Redis is optional for caching
        }
      });
    } else {
      // In production, connect immediately but don't block
      client.connect().catch((error: any) => {
        console.warn("⚠️  Redis connection error (non-critical):", error.message);
      });
    }
  }

  return client;
};

// Only create new client if one doesn't exist
if (!globalForRedis.redis) {
  globalForRedis.redis = createRedisClient();
}

export const redis = globalForRedis.redis;

// Ensure we don't create multiple clients in development
if (process.env.NODE_ENV !== "production") {
  // Reuse existing client if available
  if (globalForRedis.redis && globalForRedis.redis.status === "ready") {
    // Client already exists and is ready
  }
}

// Helper functions for common Redis operations
export const redisHelpers = {
  // Cache operations
  async cacheGet<T>(key: string): Promise<T | null> {
    try {
      const value = await redis.get(`cache:${key}`);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      console.error("Redis cache get error:", error);
      return null;
    }
  },

  async cacheSet(key: string, value: any, ttlSeconds: number = 3600): Promise<void> {
    try {
      await redis.setex(`cache:${key}`, ttlSeconds, JSON.stringify(value));
    } catch (error) {
      console.error("Redis cache set error:", error);
    }
  },

  async cacheDelete(key: string): Promise<void> {
    try {
      await redis.del(`cache:${key}`);
    } catch (error) {
      console.error("Redis cache delete error:", error);
    }
  },

  async cacheInvalidatePattern(pattern: string): Promise<void> {
    try {
      const keys = await redis.keys(`cache:${pattern}`);
      if (keys.length > 0) {
        await redis.del(...keys);
      }
    } catch (error) {
      console.error("Redis cache invalidate error:", error);
    }
  },

  // Session operations
  async sessionGet(key: string): Promise<string | null> {
    try {
      return await redis.get(`session:${key}`);
    } catch (error) {
      console.error("Redis session get error:", error);
      return null;
    }
  },

  async sessionSet(key: string, value: string, ttlSeconds: number = 86400): Promise<void> {
    try {
      await redis.setex(`session:${key}`, ttlSeconds, value);
    } catch (error) {
      console.error("Redis session set error:", error);
    }
  },

  async sessionDelete(key: string): Promise<void> {
    try {
      await redis.del(`session:${key}`);
    } catch (error) {
      console.error("Redis session delete error:", error);
    }
  },

  // Rate limiting
  async rateLimit(key: string, limit: number, windowSeconds: number): Promise<boolean> {
    try {
      const count = await redis.incr(`ratelimit:${key}`);
      if (count === 1) {
        await redis.expire(`ratelimit:${key}`, windowSeconds);
      }
      return count <= limit;
    } catch (error) {
      console.error("Redis rate limit error:", error);
      return true; // Allow on error
    }
  },

  // Analytics data caching
  async analyticsGet(key: string): Promise<any | null> {
    try {
      const value = await redis.get(`analytics:${key}`);
      return value ? JSON.parse(value) : null;
    } catch (error) {
      console.error("Redis analytics get error:", error);
      return null;
    }
  },

  async analyticsSet(key: string, value: any, ttlSeconds: number = 300): Promise<void> {
    try {
      await redis.setex(`analytics:${key}`, ttlSeconds, JSON.stringify(value));
    } catch (error) {
      console.error("Redis analytics set error:", error);
    }
  },
};

