// Prisma types - will be available after running: yarn prisma generate
// @ts-ignore - Prisma types not generated yet
import { PrismaClient } from "@prisma/client";
import { existsSync } from "fs";
import { join } from "path";

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

// Set Prisma engine for Alpine Linux with OpenSSL 3.x
// This must be set BEFORE importing PrismaClient
if (typeof window === "undefined" && !process.env.PRISMA_QUERY_ENGINE_LIBRARY) {
  // Server-side only
  try {
    // Try multiple possible paths – prioritize project directory
    // Order: musl (Alpine) first, then debian, then native
    const possiblePaths = [
      // Alpine Linux (Docker) - musl with OpenSSL 3.x
      join(
        process.cwd(),
        ".project/meowtopia/web/node_modules/.prisma/client/libquery_engine-linux-musl-openssl-3.0.x.so.node",
      ),
      "/app/.project/meowtopia/web/node_modules/.prisma/client/libquery_engine-linux-musl-openssl-3.0.x.so.node",
      // Debian/Ubuntu - glibc with OpenSSL 3.x
      join(
        process.cwd(),
        ".project/meowtopia/web/node_modules/.prisma/client/libquery_engine-debian-openssl-3.0.x.so.node",
      ),
      "/app/.project/meowtopia/web/node_modules/.prisma/client/libquery_engine-debian-openssl-3.0.x.so.node",
      // Root workspace paths
      join(
        process.cwd(),
        "node_modules/.prisma/client/libquery_engine-linux-musl-openssl-3.0.x.so.node",
      ),
      "/app/node_modules/.prisma/client/libquery_engine-linux-musl-openssl-3.0.x.so.node",
      join(
        process.cwd(),
        "node_modules/.prisma/client/libquery_engine-debian-openssl-3.0.x.so.node",
      ),
      "/app/node_modules/.prisma/client/libquery_engine-debian-openssl-3.0.x.so.node",
    ];

    for (const enginePath of possiblePaths) {
      if (existsSync(enginePath)) {
        process.env.PRISMA_QUERY_ENGINE_LIBRARY = enginePath;
        console.log("✅ Set PRISMA_QUERY_ENGINE_LIBRARY to:", enginePath);
        break;
      }
    }
    
    // If no binary found, log warning but don't crash (Prisma will show a better error)
    if (!process.env.PRISMA_QUERY_ENGINE_LIBRARY) {
      console.warn("⚠️  Could not find Prisma query engine binary. Prisma Client may fail to initialize.");
      console.warn("   Please run: yarn prisma generate");
    }
  } catch (e) {
    // Ignore if path doesn't exist
    console.warn("Could not set PRISMA_QUERY_ENGINE_LIBRARY:", e);
  }
}

// Build DATABASE_URL from project-level POSTGRES_* / POSTGRES_URL if missing.
if (typeof window === "undefined" && !process.env.DATABASE_URL) {
  try {
    const {
      POSTGRES_URL,
      POSTGRES_USER,
      POSTGRES_PASSWORD,
      POSTGRES_HOST,
      POSTGRES_PORT,
      POSTGRES_DB,
      POSTGRES_SSLMODE,
    } = process.env;

    if (POSTGRES_URL) {
      process.env.DATABASE_URL = POSTGRES_URL;
    } else {
      const user = POSTGRES_USER || "postgres";
      const password = POSTGRES_PASSWORD || "postgres";
      const host = POSTGRES_HOST || "devcontainer-postgres";
      const port = POSTGRES_PORT || "5432";
      const db = POSTGRES_DB || "meowtopia";
      const sslmode = POSTGRES_SSLMODE || "disable";

      process.env.DATABASE_URL = `postgresql://${user}:${password}@${host}:${port}/${db}?sslmode=${sslmode}&schema=public`;
    }

    console.log("✅ DATABASE_URL built from project-level POSTGRES_* variables");
  } catch (e) {
    console.error("DATABASE_URL is not set and could not be derived from POSTGRES_* vars.");
    console.error("Please set POSTGRES_URL or POSTGRES_* in .env.project for Meowtopia.");
  }
}

export const prisma =
  globalForPrisma.prisma ??
  new PrismaClient({
    log: process.env.NODE_ENV === "development" ? ["error", "warn"] : ["error"],
  });

if (process.env.NODE_ENV !== "production") globalForPrisma.prisma = prisma;

// Test connection on startup in development
if (process.env.NODE_ENV === "development" && typeof window === "undefined") {
  setImmediate(() => {
    prisma
      .$connect()
      .then(() => {
        console.log("✅ Prisma connected to PostgreSQL database");
      })
      .catch((error) => {
        console.error("❌ Prisma connection error:", error.message);
        if (!process.env.DATABASE_URL) {
          console.error("⚠️  DATABASE_URL is not set in environment variables");
        }
      });
  });
}
