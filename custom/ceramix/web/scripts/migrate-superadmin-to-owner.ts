/**
 * Migration script to convert all superadmin roles to owner
 * Run this once to clean up the database
 */

import { query } from "../lib/db";

export async function migrateSuperadminToOwner() {
  console.log("🔄 Starting migration: superadmin -> owner");

  try {
    // 1. Update user_roles table - change superadmin to owner
    const userRolesResult = await query(`
      UPDATE user_roles 
      SET role = 'owner' 
      WHERE role = 'superadmin'
      RETURNING id, user_id
    `);
    console.log(`✅ Updated ${userRolesResult.rows.length} user_roles from superadmin to owner`);

    // 2. Remove superadmin from role_groups
    const roleGroupsResult = await query(`
      DELETE FROM role_groups 
      WHERE role_key = 'superadmin'
      RETURNING id
    `);
    console.log(`✅ Removed ${roleGroupsResult.rows.length} superadmin entries from role_groups`);

    // 3. Ensure owner role exists in role_groups
    await query(`
      INSERT INTO role_groups (role_key, label, description, color_class, sort_order)
      VALUES ('owner', 'Właściciel', 'Pełny dostęp i kontrola ról', 'bg-purple-500/20 text-purple-400', 40)
      ON CONFLICT (role_key) DO UPDATE SET
        label = EXCLUDED.label,
        description = EXCLUDED.description,
        color_class = EXCLUDED.color_class,
        sort_order = EXCLUDED.sort_order,
        updated_at = CURRENT_TIMESTAMP
    `);
    console.log("✅ Ensured owner role exists in role_groups");

    // 4. Verify migration
    const superadminCount = await query(`
      SELECT COUNT(*) as count 
      FROM user_roles 
      WHERE role = 'superadmin'
    `);
    const ownerCount = await query(`
      SELECT COUNT(*) as count 
      FROM user_roles 
      WHERE role = 'owner'
    `);

    console.log(`📊 Verification:`);
    console.log(`   - Remaining superadmin roles: ${superadminCount.rows[0].count}`);
    console.log(`   - Owner roles: ${ownerCount.rows[0].count}`);

    if (superadminCount.rows[0].count === "0") {
      console.log("✅ Migration completed successfully!");
      return true;
    } else {
      console.log("⚠️  Warning: Some superadmin roles still exist");
      return false;
    }
  } catch (error: any) {
    console.error("❌ Migration failed:", error);
    throw error;
  }
}

// Run migration if called directly
if (require.main === module) {
  migrateSuperadminToOwner()
    .then(() => {
      console.log("Migration script completed");
      process.exit(0);
    })
    .catch((error) => {
      console.error("Migration script failed:", error);
      process.exit(1);
    });
}


