/**
 * Script to run the migration that changes users.id from UUID to VARCHAR(50)
 * This fixes the error: "invalid input syntax for type uuid: 'OWN-20251127-221112-000001'"
 */

import { readFileSync } from "fs";
import { join } from "path";
import { query } from "../lib/db";

async function runMigration() {
  console.log("🔄 Starting migration: users.id from UUID to VARCHAR(50)\n");
  console.log("⚠️  WARNING: This will modify your database schema!");
  console.log("⚠️  Make sure you have a backup!\n");

  try {
    // Read the migration SQL file
    const migrationPath = join(__dirname, "migrate-users-table-to-varchar.sql");
    console.log(`📄 Reading migration file: ${migrationPath}`);
    const migrationSQL = readFileSync(migrationPath, "utf-8");

    // Execute the migration
    console.log("🚀 Executing migration...\n");
    await query(migrationSQL);

    console.log("\n✅ Migration completed successfully!");
    console.log("\n📝 Next steps:");
    console.log("   1. The users.id column is now VARCHAR(50)");
    console.log("   2. All foreign key columns have been updated");
    console.log("   3. You can now add users with role-based IDs (e.g., OWN-20251127-221112-000001)");
    console.log("\n💡 Note: Existing user IDs have been converted from UUID to VARCHAR format");
    console.log("   If you want to convert them to role-based IDs, run: yarn migrate:all-users");
  } catch (error: any) {
    console.error("\n❌ Migration failed:", error.message);
    if (error.code) {
      console.error("   Error code:", error.code);
    }
    if (error.detail) {
      console.error("   Details:", error.detail);
    }
    throw error;
  }
}

// Run if called directly
if (require.main === module) {
  runMigration()
    .then(() => {
      console.log("\n✅ Script completed!");
      process.exit(0);
    })
    .catch((error) => {
      console.error("\n❌ Script failed:", error);
      process.exit(1);
    });
}

export { runMigration };


