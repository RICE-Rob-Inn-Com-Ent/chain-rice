/**
 * Migration script to convert UUID user IDs to role-based IDs
 * 
 * WARNING: This is a destructive migration!
 * Make sure to backup your database before running this.
 */

import { query, queryOne } from "../lib/db";
import { generateUserId, getRolePrefix } from "../lib/user-id-generator";

async function migrateUserIds() {
  console.log("🔄 Starting user ID migration...\n");
  console.log("⚠️  WARNING: This will change all user IDs!");
  console.log("⚠️  Make sure you have a database backup!\n");

  try {
    // Get all users with their roles
    const users = await query(`
      SELECT 
        u.id as old_id,
        u.email,
        u.display_name,
        COALESCE(
          (SELECT role FROM user_roles WHERE user_id = u.id ORDER BY granted_at DESC LIMIT 1),
          'user'
        ) as role
      FROM users u
      ORDER BY u.created_at
    `);

    console.log(`Found ${users.rows.length} users to migrate\n`);

    // Create mapping of old IDs to new IDs
    const idMapping: Record<string, string> = {};

    for (const user of users.rows) {
      const newId = await generateUserId(user.role);
      idMapping[user.old_id] = newId;
      console.log(`  ${user.email} (${user.role}): ${user.old_id} -> ${newId}`);
    }

    console.log("\n⚠️  Migration mapping created. To apply, uncomment the migration code below.");
    console.log("⚠️  This will update all foreign key references!\n");

    // UNCOMMENT BELOW TO ACTUALLY RUN THE MIGRATION
    /*
    // Step 1: Disable foreign key constraints temporarily
    await query(`SET session_replication_role = 'replica'`);

    // Step 2: Update all foreign key references
    const tablesToUpdate = [
      { table: 'user_roles', column: 'user_id' },
      { table: 'user_roles', column: 'granted_by' },
      { table: 'patient_profiles', column: 'user_id' },
      { table: 'sessions', column: 'user_id' },
      // Add other tables that reference users.id
    ];

    for (const { table, column } of tablesToUpdate) {
      console.log(`Updating ${table}.${column}...`);
      for (const [oldId, newId] of Object.entries(idMapping)) {
        await query(
          `UPDATE ${table} SET ${column} = $1 WHERE ${column} = $2`,
          [newId, oldId]
        );
      }
    }

    // Step 3: Update users table
    console.log("Updating users table...");
    for (const [oldId, newId] of Object.entries(idMapping)) {
      await query(
        `UPDATE users SET id = $1 WHERE id = $2`,
        [newId, oldId]
      );
    }

    // Step 4: Re-enable foreign key constraints
    await query(`SET session_replication_role = 'origin'`);

    console.log("\n✅ Migration completed!");
    */

  } catch (error: any) {
    console.error("❌ Migration error:", error);
    throw error;
  }
}

// Run if called directly
if (require.main === module) {
  migrateUserIds()
    .then(() => {
      console.log("\n✅ Migration script completed!");
      process.exit(0);
    })
    .catch((error) => {
      console.error("❌ Migration failed:", error);
      process.exit(1);
    });
}

export { migrateUserIds };






















































