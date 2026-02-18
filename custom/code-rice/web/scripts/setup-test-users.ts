/**
 * Setup test users for Code-Rice
 * 
 * This script:
 * 1. Runs migration to change users.id from UUID to TEXT (if needed)
 * 2. Seeds test users with role-prefixed IDs
 * 
 * Usage: tsx scripts/setup-test-users.ts
 */

import { readFileSync } from "fs";
import { join } from "path";
import { pool } from "../lib/db";
import { seedTestUsers } from "./seed-test-users";

async function runMigration() {
  console.log("🔄 Checking database schema...\n");

  // Check if users.id is already TEXT
  const result = await pool.query(`
    SELECT data_type 
    FROM information_schema.columns 
    WHERE table_name = 'users' AND column_name = 'id'
  `);

  if (result.rows.length === 0) {
    console.log("⚠️  Users table doesn't exist. Please run init script first.");
    return false;
  }

  const currentType = result.rows[0].data_type;
  
  if (currentType === "text" || currentType === "character varying") {
    console.log("✅ Users table already uses TEXT/VARCHAR for id column.\n");
    return true;
  }

  if (currentType !== "uuid") {
    console.log(`⚠️  Unexpected column type: ${currentType}. Skipping migration.`);
    return false;
  }

  console.log("📝 Users table uses UUID. Running migration to TEXT...\n");

  try {
    const migrationSQL = readFileSync(
      join(__dirname, "../lib/db/migrate-to-role-ids.sql"),
      "utf-8"
    );

    const client = await pool.connect();
    
    try {
      // Execute the entire migration as one transaction
      await client.query(migrationSQL);
      console.log("✅ Migration completed successfully!\n");
      return true;
    } catch (error: any) {
      console.error("❌ Migration failed:", error.message);
      console.error("\nPlease run the migration manually:");
      console.error("  psql -d code-rice -f lib/db/migrate-to-role-ids.sql");
      throw error;
    } finally {
      client.release();
    }
  } catch (error: any) {
    if (!error.message.includes("Migration failed")) {
      console.error("❌ Error reading or executing migration:", error.message);
      console.error("\nPlease run the migration manually:");
      console.error("  psql -d code-rice -f lib/db/migrate-to-role-ids.sql");
    }
    return false;
  }
}

async function setupTestUsers() {
  console.log("🌱 Setting up test users for Code-Rice...\n");

  try {
    const migrationSuccess = await runMigration();
    
    if (!migrationSuccess) {
      console.log("\n⚠️  Skipping user seeding due to migration issues.");
      process.exit(1);
    }

    console.log("📦 Seeding test users...\n");
    await seedTestUsers();
    
    console.log("\n✨ Setup completed successfully!");
  } catch (error) {
    console.error("\n❌ Error:", error);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

// Run if executed directly
if (require.main === module) {
  setupTestUsers();
}

export { setupTestUsers };

