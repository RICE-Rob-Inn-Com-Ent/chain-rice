/**
 * Script to fix foreign key constraint on patient_profiles table
 */

import { query, queryOne } from "../lib/db";

async function fixForeignKey() {
  console.log("🔧 Fixing foreign key constraint on patient_profiles...\n");

  try {
    // Check if constraint already exists
    const fkExists = await queryOne<{ exists: boolean }>(
      `SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_schema = 'public' 
          AND table_name = 'patient_profiles' 
          AND constraint_name = 'patient_profiles_user_id_fkey'
          AND constraint_type = 'FOREIGN KEY'
      ) as exists`
    );

    if (fkExists?.exists) {
      console.log("✅ Foreign key constraint already exists!");
      return;
    }

    // Check if there are any orphaned records
    const orphaned = await query(`
      SELECT pp.user_id
      FROM patient_profiles pp
      LEFT JOIN users u ON pp.user_id = u.id
      WHERE u.id IS NULL
    `);

    if (orphaned.rows.length > 0) {
      console.log(`⚠️  Found ${orphaned.rows.length} orphaned patient profiles. Removing them...`);
      for (const orphan of orphaned.rows) {
        await query(`DELETE FROM patient_profiles WHERE user_id = $1`, [orphan.user_id]);
        console.log(`   Removed orphaned profile for user_id: ${orphan.user_id}`);
      }
    }

    // Add foreign key constraint
    console.log("Adding foreign key constraint...");
    await query(`
      ALTER TABLE patient_profiles
      ADD CONSTRAINT patient_profiles_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
    `);

    console.log("✅ Foreign key constraint added successfully!\n");

    // Verify it was added
    const verify = await queryOne<{ exists: boolean }>(
      `SELECT EXISTS (
        SELECT 1 FROM information_schema.table_constraints 
        WHERE table_schema = 'public' 
          AND table_name = 'patient_profiles' 
          AND constraint_name = 'patient_profiles_user_id_fkey'
          AND constraint_type = 'FOREIGN KEY'
      ) as exists`
    );

    if (verify?.exists) {
      console.log("✅ Verification: Foreign key constraint confirmed!");
    } else {
      console.log("❌ Verification failed: Constraint not found after adding!");
    }

  } catch (error: any) {
    console.error("❌ Error fixing foreign key:", error);
    if (error.message.includes("already exists")) {
      console.log("ℹ️  Constraint already exists (this is OK)");
    } else {
      throw error;
    }
  }
}

// Run if called directly
if (require.main === module) {
  fixForeignKey()
    .then(() => {
      console.log("\n✅ Fix completed!");
      process.exit(0);
    })
    .catch((error) => {
      console.error("❌ Fix failed:", error);
      process.exit(1);
    });
}

export { fixForeignKey };






















































