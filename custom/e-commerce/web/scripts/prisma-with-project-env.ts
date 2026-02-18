import { config as loadEnv } from "dotenv";
import { join } from "path";
import { spawn } from "child_process";

// Load project-level env file (.env.project one level up from web/)
loadEnv({ path: join(process.cwd(), "..", ".env.project") });

function buildDatabaseUrl(): string {
  const explicitUrl = process.env.POSTGRES_URL;
  if (explicitUrl) {
    return explicitUrl;
  }

  const user = process.env.POSTGRES_USER || "postgres";
  const password = process.env.POSTGRES_PASSWORD || "postgres";
  const host = process.env.POSTGRES_HOST || "devcontainer-postgres";
  const port = process.env.POSTGRES_PORT || "5432";
  const db = process.env.POSTGRES_DB || "meowtopia";
  const sslmode = process.env.POSTGRES_SSLMODE || "disable";

  return `postgresql://${user}:${password}@${host}:${port}/${db}?sslmode=${sslmode}&schema=public`;
}

// Ensure DATABASE_URL is set for Prisma CLI before spawning it
if (!process.env.DATABASE_URL) {
  process.env.DATABASE_URL = buildDatabaseUrl();
  console.log("✅ [prisma-with-project-env] DATABASE_URL set from project-level POSTGRES_* variables");
}

// Forward all args after the script name to the `prisma` CLI
const [, , ...prismaArgs] = process.argv;

if (prismaArgs.length === 0) {
  console.error("Usage: tsx scripts/prisma-with-project-env.ts <prisma-args>");
  process.exit(1);
}

const child = spawn("prisma", prismaArgs, {
  stdio: "inherit",
  env: process.env,
});

child.on("exit", (code) => {
  process.exit(code ?? 1);
});




