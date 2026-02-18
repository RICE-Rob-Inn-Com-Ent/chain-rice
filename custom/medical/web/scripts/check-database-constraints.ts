/**
 * Script to check database constraints and verify patient_profiles setup
 */

import { query, queryOne } from "../lib/db";

async function checkDatabaseConstraints() {
  console.log("🔍 Checking database constraints and setup...\n");

  try {
    // 1. Check if patient_profiles table exists
    console.log("1. Checking if patient_profiles table exists...");
    const tableExists = await queryOne<{ exists: boolean }>(
      `SELECT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_schema = 'public' AND table_name = 'patient_profiles'
      ) as exists`
    );
    console.log(`   Table exists: ${tableExists?.exists ? "✅" : "❌"}\n`);

    if (!tableExists?.exists) {
      console.log("❌ patient_profiles table does not exist!");
      return;
    }

    // 2. Check foreign key constraints
    console.log("2. Checking foreign key constraints...");
    const fkConstraints = await query(`
      SELECT 
        conname as constraint_name,
        conrelid::regclass as table_name,
        confrelid::regclass as foreign_table_name,
        a.attname as column_name,
        af.attname as foreign_column_name
      FROM pg_constraint c
      JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = ANY(c.conkey)
      JOIN pg_attribute af ON af.attrelid = c.confrelid AND af.attnum = ANY(c.confkey)
      WHERE conrelid = 'patient_profiles'::regclass
        AND contype = 'f'
    `);

    if (fkConstraints.rows.length > 0) {
      console.log("   Foreign key constraints found:");
      fkConstraints.rows.forEach((fk: any) => {
        console.log(`   ✅ ${fk.constraint_name}: ${fk.table_name}.${fk.column_name} -> ${fk.foreign_table_name}.${fk.foreign_column_name}`);
      });
    } else {
      console.log("   ❌ No foreign key constraints found!");
    }
    console.log();

    // 3. Check users table structure
    console.log("3. Checking users table structure...");
    const usersColumns = await query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'users' AND column_name = 'id'
    `);
    
    if (usersColumns.rows.length > 0) {
      const idColumn = usersColumns.rows[0];
      console.log(`   ✅ users.id: ${idColumn.data_type} (nullable: ${idColumn.is_nullable})`);
    } else {
      console.log("   ❌ users.id column not found!");
    }
    console.log();

    // 4. Check patient_profiles table structure
    console.log("4. Checking patient_profiles table structure...");
    const profileColumns = await query(`
      SELECT column_name, data_type, is_nullable
      FROM information_schema.columns
      WHERE table_name = 'patient_profiles' AND column_name = 'user_id'
    `);
    
    if (profileColumns.rows.length > 0) {
      const userIdColumn = profileColumns.rows[0];
      console.log(`   ✅ patient_profiles.user_id: ${userIdColumn.data_type} (nullable: ${userIdColumn.is_nullable})`);
    } else {
      console.log("   ❌ patient_profiles.user_id column not found!");
    }
    console.log();

    // 5. Check sample users
    console.log("5. Checking sample users in database...");
    const sampleUsers = await query(`
      SELECT id, email, display_name, active
      FROM users
      LIMIT 5
    `);
    
    if (sampleUsers.rows.length > 0) {
      console.log(`   Found ${sampleUsers.rows.length} users:`);
      sampleUsers.rows.forEach((user: any) => {
        console.log(`   - ${user.email} (${user.id}) - ${user.active ? "Active" : "Inactive"}`);
      });
    } else {
      console.log("   ❌ No users found in database!");
    }
    console.log();

    // 6. Check existing patient profiles
    console.log("6. Checking existing patient profiles...");
    const profiles = await query(`
      SELECT user_id, 
             (SELECT email FROM users WHERE id = patient_profiles.user_id) as user_email
      FROM patient_profiles
      LIMIT 5
    `);
    
    if (profiles.rows.length > 0) {
      console.log(`   Found ${profiles.rows.length} patient profiles:`);
      profiles.rows.forEach((profile: any) => {
        console.log(`   - User: ${profile.user_email} (${profile.user_id})`);
      });
    } else {
      console.log("   ℹ️  No patient profiles found (this is OK if none created yet)");
    }
    console.log();

    // 7. Check for orphaned patient profiles (user_id that doesn't exist in users)
    console.log("7. Checking for orphaned patient profiles...");
    const orphaned = await query(`
      SELECT pp.user_id
      FROM patient_profiles pp
      LEFT JOIN users u ON pp.user_id = u.id
      WHERE u.id IS NULL
    `);
    
    if (orphaned.rows.length > 0) {
      console.log(`   ⚠️  Found ${orphaned.rows.length} orphaned patient profiles:`);
      orphaned.rows.forEach((orphan: any) => {
        console.log(`   - Orphaned user_id: ${orphan.user_id}`);
      });
    } else {
      console.log("   ✅ No orphaned patient profiles found");
    }
    console.log();

    // 8. Test UUID format validation
    console.log("8. Testing UUID format...");
    const testUuid = "123e4567-e89b-12d3-a456-426614174000";
    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const isValidUuid = uuidRegex.test(testUuid);
    console.log(`   Test UUID: ${testUuid}`);
    console.log(`   Valid format: ${isValidUuid ? "✅" : "❌"}`);
    console.log();

    console.log("✅ Database check completed!");

  } catch (error: any) {
    console.error("❌ Error checking database:", error);
    console.error("Stack:", error.stack);
  }
}

// Run if called directly
if (require.main === module) {
  checkDatabaseConstraints()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

export { checkDatabaseConstraints };

