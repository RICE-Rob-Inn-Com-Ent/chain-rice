import { Pool } from "pg";

const DEFAULT_CONNECTION =
  "postgresql://code_rice_user:code_rice_password@devcontainer-postgres:5432/code-rice?sslmode=disable";

function resolveConnectionString(): string {
  if (process.env.CODE_RICE_DATABASE_URL) {
    return process.env.CODE_RICE_DATABASE_URL;
  }

  if (process.env.DATABASE_URL) {
    return process.env.DATABASE_URL;
  }

  const host = process.env.POSTGRES_HOST || "devcontainer-postgres";
  const port = process.env.POSTGRES_PORT || "5432";
  const user = process.env.POSTGRES_USER || "code_rice_user";
  const password = process.env.POSTGRES_PASSWORD || "code_rice_password";
  const database = process.env.POSTGRES_DB || "code-rice";

  return `postgresql://${user}:${password}@${host}:${port}/${database}?sslmode=disable`;
}

const connectionString = resolveConnectionString() || DEFAULT_CONNECTION;

console.log("[code-rice][db] using connection:", connectionString.replace(/:[^:@]+@/, ":****@"));

export const pool = new Pool({
  connectionString,
  max: 15,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});

export async function query<T = any>(text: string, params?: any[]): Promise<{ rows: T[]; rowCount: number }> {
  const start = Date.now();
  try {
    const result = await pool.query<T>(text, params);
    const duration = Date.now() - start;
    if (process.env.NODE_ENV === "development") {
      console.log("[code-rice][db] query", { text: text.slice(0, 80), duration, rows: result.rowCount });
    }
    return result;
  } catch (error) {
    console.error("[code-rice][db] query error", { text: text.slice(0, 80), error });
    throw error;
  }
}

export async function queryOne<T = any>(text: string, params?: any[]): Promise<T | null> {
  const result = await query<T>(text, params);
  return result.rows[0] ?? null;
}

export async function queryMany<T = any>(text: string, params?: any[]): Promise<T[]> {
  const result = await query<T>(text, params);
  return result.rows;
}

export async function transaction<T>(handler: (client: any) => Promise<T>): Promise<T> {
  const client = await pool.connect();
  try {
    await client.query("BEGIN");
    const result = await handler(client);
    await client.query("COMMIT");
    return result;
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
}


