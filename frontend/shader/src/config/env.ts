/**
 * Environment configuration validated at startup with Valibot.
 * Uses Bun.env; fail fast if required vars are missing or invalid.
 */
import * as v from "valibot";

const envSchema = v.object({
  NODE_ENV: v.pipe(
    v.optional(v.string(), "development"),
    v.transform((s) => (s === "production" ? "production" : "development")),
  ),
  PORT: v.pipe(
    v.optional(v.string(), "3000"),
    v.pipe(v.string(), v.regex(/^\d+$/), v.transform((s) => Number.parseInt(s, 10))),
  ),
  /** Base URL of the Go User service (Connect/gRPC). */
  USER_SERVICE_URL: v.pipe(
    v.optional(v.string(), "http://localhost:8080"),
    v.url("USER_SERVICE_URL must be a valid URL"),
  ),
  /** Optional: Python/Bot service URL for future use. */
  BOT_SERVICE_URL: v.optional(
    v.pipe(v.string(), v.url("BOT_SERVICE_URL must be a valid URL")),
  ),
});

export type Env = v.InferOutput<typeof envSchema>;

let cached: Env | null = null;

/**
 * Load and validate env once at startup. Uses Bun.env.
 * @throws Valibot error if validation fails
 */
export function loadEnv(): Env {
  if (cached) return cached;
  const raw = {
    NODE_ENV: Bun.env.NODE_ENV,
    PORT: Bun.env.PORT,
    USER_SERVICE_URL: Bun.env.USER_SERVICE_URL,
    BOT_SERVICE_URL: Bun.env.BOT_SERVICE_URL,
  };
  cached = v.parse(envSchema, raw);
  return cached;
}
