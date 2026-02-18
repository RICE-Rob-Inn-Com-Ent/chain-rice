import { getPool } from "../../../../../../.devcontainer/typescript/db";
import { readFileSync } from "fs";
import { join } from "path";

export async function initializeDatabase() {
  const pool = getPool();
  const schemaPath = join(process.cwd(), "scripts/shared-lib-db/schema.sql");
  
  try {
    const schema = readFileSync(schemaPath, "utf-8");
    await pool.query(schema);
    console.log("Database schema initialized successfully");
  } catch (error: any) {
    if (error.code === "42P07") {
      // Table already exists
      console.log("Database schema already exists");
    } else {
      console.error("Error initializing database:", error);
      throw error;
    }
  }
}

// Run initialization if this file is executed directly
if (require.main === module) {
  initializeDatabase()
    .then(() => {
      console.log("Database initialization complete");
      process.exit(0);
    })
    .catch((error) => {
      console.error("Database initialization failed:", error);
      process.exit(1);
    });
}

