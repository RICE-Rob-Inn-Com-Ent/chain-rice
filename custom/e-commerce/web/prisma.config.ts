import { config as loadEnv } from "dotenv";
import { join } from "path";
import { existsSync } from "fs";
import { defineConfig, env } from "prisma/config";

// Load project-wide env file BEFORE Prisma reads any env vars.
// This config is intended to work for all Meowtopia apps (web, database tools, etc.)
// as long as they live under `.project/meowtopia/*`.
function loadProjectEnv() {
  const cwd = process.cwd();

  // Candidate locations relative to different app folders:
  // - web:      .project/meowtopia/web       -> ../.env.project
  // - database: .project/meowtopia/database  -> ../.env.project
  // - bot:      .project/meowtopia/bot       -> ../.env.project
  const candidates = [
    join(cwd, "..", ".env.project"),
    join(cwd, "..", "..", ".env.project"),
  ];

  for (const candidate of candidates) {
    if (existsSync(candidate)) {
      loadEnv({ path: candidate });
      return;
    }
  }

  // Fallback: do nothing if not found – Prisma will still fail loudly on missing DATABASE_URL
}

loadProjectEnv();

// Build DATABASE_URL from project-level POSTGRES_* / POSTGRES_URL
function buildDatabaseUrl(): string {
  // 1) If POSTGRES_URL is provided, prefer it (keeps backward compatibility)
  const explicitUrl = env("POSTGRES_URL");
  if (explicitUrl) {
    process.env.DATABASE_URL = explicitUrl;
    return explicitUrl;
  }

  // 2) Otherwise, compose from individual POSTGRES_* pieces
  const user = env("POSTGRES_USER") || "postgres";
  const password = env("POSTGRES_PASSWORD") || "postgres";
  const host = env("POSTGRES_HOST") || "devcontainer-postgres";
  const port = env("POSTGRES_PORT") || "5432";
  const db = env("POSTGRES_DB") || "meowtopia";
  const sslmode = env("POSTGRES_SSLMODE") || "disable";

  const url = `postgresql://${user}:${password}@${host}:${port}/${db}?sslmode=${sslmode}&schema=public`;
  process.env.DATABASE_URL = url;
  return url;
}

const databaseUrl = buildDatabaseUrl();

export default defineConfig({
  schema: "prisma/schema.prisma",
  migrations: {
    path: "prisma/migrations",
  },
  // Force Prisma CLI to use the same URL that runtime will derive
  datasource: {
    url: databaseUrl,
  },
});

