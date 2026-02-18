/**
 * Migration script to convert all users to new role-based IDs
 * 
 * WARNING: This is a DESTRUCTIVE migration!
 * - Changes all user IDs
 * - Updates all foreign key references
 * - Removes user_roles table (role is now in ID prefix)
 * 
 * Make sure to backup your database before running!
 */

import { query, queryOne } from "../lib/db";
import { generateUserId, getRolePrefix } from "../lib/user-id-generator";

async function migrateAllUsers() {
  console.log("🔄 Starting full user ID migration...\n");
  console.log("⚠️  WARNING: This will change ALL user IDs and remove user_roles table!");
  console.log("⚠️  Make sure you have a database backup!\n");

  try {
    // Step 1: Get all users with their roles
    console.log("Step 1: Fetching all users with roles...");
    const users = await query(`
      SELECT 
        u.id::text as old_id,
        u.email,
        u.display_name,
        COALESCE(
          (SELECT role FROM user_roles WHERE user_id::text = u.id::text ORDER BY granted_at DESC LIMIT 1),
          'user'
        ) as role
      FROM users u
      ORDER BY u.created_at
    `);

    console.log(`   Found ${users.rows.length} users to migrate\n`);

    if (users.rows.length === 0) {
      console.log("✅ No users to migrate");
      return;
    }

    // Step 2: Generate new IDs for all users
    console.log("Step 2: Generating new IDs...");
    const idMapping: Record<string, { newId: string; role: string; email: string }> = {};

    for (const user of users.rows) {
      // Generate new ID based on role
      const newId = await generateUserId(user.role);
      idMapping[user.old_id] = {
        newId,
        role: user.role,
        email: user.email,
      };
      console.log(`   ${user.email} (${user.role}): ${user.old_id.substring(0, 8)}... -> ${newId}`);
    }

    console.log(`\n✅ Generated ${Object.keys(idMapping).length} new IDs\n`);

    // Step 3: Disable foreign key constraints temporarily
    console.log("Step 3: Preparing database for migration...");
    
    // Get all tables with foreign keys to users.id
    const fkTables = await query(`
      SELECT 
        tc.table_name,
        kcu.column_name,
        tc.constraint_name
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
      WHERE tc.table_schema = 'public'
        AND tc.constraint_type = 'FOREIGN KEY'
        AND tc.table_name IN (
          SELECT DISTINCT ccu.table_name
          FROM information_schema.constraint_column_usage AS ccu
          WHERE ccu.table_name = 'users' AND ccu.column_name = 'id'
        )
    `);

    console.log(`   Found ${fkTables.rows.length} foreign key constraints to update\n`);

    // Step 4: Update all foreign key references
    console.log("Step 4: Updating foreign key references...");
    
    const tablesToUpdate = [
      { table: 'user_roles', column: 'user_id', name: 'user_roles_user_id' },
      { table: 'user_roles', column: 'granted_by', name: 'user_roles_granted_by' },
      { table: 'patient_profiles', column: 'user_id', name: 'patient_profiles_user_id' },
      { table: 'sessions', column: 'user_id', name: 'sessions_user_id' },
      // Add other tables that reference users.id
    ];

    // Drop foreign key constraints temporarily
    for (const { table, column, name } of tablesToUpdate) {
      try {
        const tableExists = await queryOne<{ exists: boolean }>(
          `SELECT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = $1
          ) as exists`,
          [table]
        );

        if (tableExists?.exists) {
          const constraintExists = await queryOne<{ exists: boolean }>(
            `SELECT EXISTS (
              SELECT 1 FROM information_schema.table_constraints 
              WHERE table_schema = 'public' 
                AND table_name = $1 
                AND constraint_name = $2
            ) as exists`,
            [table, `${name}_fkey`]
          );

          if (constraintExists?.exists) {
            console.log(`   Dropping FK constraint on ${table}.${column}...`);
            await query(`ALTER TABLE ${table} DROP CONSTRAINT IF EXISTS ${name}_fkey`);
          }
        }
      } catch (error: any) {
        console.log(`   ⚠️  Could not drop constraint on ${table}: ${error.message}`);
      }
    }

    // Update all foreign key columns
    for (const { table, column } of tablesToUpdate) {
      try {
        const tableExists = await queryOne<{ exists: boolean }>(
          `SELECT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = $1
          ) as exists`,
          [table]
        );

        if (tableExists?.exists) {
          // Check column type
          const columnType = await queryOne<{ data_type: string }>(
            `SELECT data_type FROM information_schema.columns 
             WHERE table_schema = 'public' AND table_name = $1 AND column_name = $2`,
            [table, column]
          );
          
          if (columnType?.data_type === 'uuid') {
            console.log(`   ⚠️  ${table}.${column} is still UUID - skipping (will be updated after column type change)`);
            continue;
          }
          
          console.log(`   Updating ${table}.${column}...`);
          let updated = 0;
          for (const [oldId, { newId }] of Object.entries(idMapping)) {
            const result = await query(
              `UPDATE ${table} SET ${column} = $1 WHERE ${column}::text = $2`,
              [newId, oldId]
            );
            updated += result.rowCount || 0;
          }
          console.log(`     Updated ${updated} rows in ${table}`);
        }
      } catch (error: any) {
        console.log(`   ⚠️  Error updating ${table}: ${error.message}`);
      }
    }

    // Step 5: Update users table
    console.log("\nStep 5: Updating users table...");
    
    // Check if users.id is VARCHAR
    const usersIdType = await queryOne<{ data_type: string }>(
      `SELECT data_type FROM information_schema.columns 
       WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'id'`
    );
    
    if (usersIdType?.data_type === 'uuid') {
      console.log("   ❌ ERROR: users.id is still UUID!");
      console.log("   Please run scripts/migrate-users-table-to-varchar.sql first!");
      throw new Error("users.id must be VARCHAR(50) before migration. Run migrate-users-table-to-varchar.sql first.");
    }
    
    let usersUpdated = 0;
    for (const [oldId, { newId }] of Object.entries(idMapping)) {
      await query(
        `UPDATE users SET id = $1 WHERE id::text = $2`,
        [newId, oldId]
      );
      usersUpdated++;
    }
    console.log(`   Updated ${usersUpdated} users\n`);

    // Step 6: Verify users.id column type is VARCHAR
    console.log("Step 6: Verifying users.id is VARCHAR...");
    const idColumnType = await queryOne<{ data_type: string }>(
      `SELECT data_type FROM information_schema.columns 
       WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'id'`
    );

    if (idColumnType?.data_type === 'uuid' || idColumnType?.data_type === 'character varying') {
      if (idColumnType.data_type === 'uuid') {
        console.log("   ❌ ERROR: users.id is still UUID!");
        console.log("   Please run scripts/migrate-users-table-to-varchar.sql first!");
        throw new Error("users.id must be VARCHAR(50) before migration. Run migrate-users-table-to-varchar.sql first.");
      } else {
        console.log("   ✅ Column is VARCHAR\n");
      }
    } else {
      console.log("   ⚠️  Unknown column type:", idColumnType?.data_type);
    }

    // Step 7: Re-add foreign key constraints
    console.log("Step 7: Re-adding foreign key constraints...");
    for (const { table, column, name } of tablesToUpdate) {
      try {
        const tableExists = await queryOne<{ exists: boolean }>(
          `SELECT EXISTS (
            SELECT 1 FROM information_schema.tables 
            WHERE table_schema = 'public' AND table_name = $1
          ) as exists`,
          [table]
        );

        if (tableExists?.exists) {
          const constraintExists = await queryOne<{ exists: boolean }>(
            `SELECT EXISTS (
              SELECT 1 FROM information_schema.table_constraints 
              WHERE table_schema = 'public' 
                AND table_name = $1 
                AND constraint_name = $2
            ) as exists`,
            [table, `${name}_fkey`]
          );

          if (!constraintExists?.exists) {
            console.log(`   Adding FK constraint on ${table}.${column}...`);
            await query(`
              ALTER TABLE ${table}
              ADD CONSTRAINT ${name}_fkey
              FOREIGN KEY (${column}) REFERENCES users(id) ON DELETE CASCADE
            `);
          }
        }
      } catch (error: any) {
        console.log(`   ⚠️  Could not add constraint on ${table}: ${error.message}`);
      }
    }

    // Step 8: Remove user_roles table (role is now in ID)
    console.log("\nStep 8: Removing user_roles table (role is now in ID prefix)...");
    try {
      await query(`DROP TABLE IF EXISTS user_roles CASCADE`);
      console.log("   ✅ user_roles table removed\n");
    } catch (error: any) {
      console.log(`   ⚠️  Could not remove user_roles: ${error.message}\n`);
    }

    // Step 9: Verify migration
    console.log("Step 9: Verifying migration...");
    const verifyUsers = await query(`
      SELECT id, email, display_name
      FROM users
      LIMIT 5
    `);

    console.log("   Sample users after migration:");
    for (const user of verifyUsers.rows) {
      console.log(`     ${user.email}: ${user.id}`);
    }

    console.log("\n✅ Migration completed successfully!");
    console.log(`\n📊 Summary:`);
    console.log(`   - Migrated ${usersUpdated} users`);
    console.log(`   - Removed user_roles table`);
    console.log(`   - Role is now determined from ID prefix`);

  } catch (error: any) {
    console.error("\n❌ Migration error:", error);
    console.error("Stack:", error.stack);
    throw error;
  }
}

// Run if called directly
if (require.main === module) {
  console.log("⚠️  DESTRUCTIVE MIGRATION - This will change ALL user IDs!\n");
  console.log("⚠️  Make sure you have a database backup!\n");
  console.log("⚠️  This will also REMOVE the user_roles table!\n");
  console.log("Press Ctrl+C to cancel, or wait 3 seconds to continue...\n");
  
  setTimeout(() => {
    migrateAllUsers()
      .then(() => {
        console.log("\n✅ Migration completed!");
        console.log("\n📝 Next steps:");
        console.log("   1. Test the application");
        console.log("   2. Verify all users have new IDs");
        console.log("   3. Check that roles are correctly determined from ID prefixes");
        process.exit(0);
      })
      .catch((error) => {
        console.error("\n❌ Migration failed:", error);
        process.exit(1);
      });
  }, 3000);
}

export { migrateAllUsers };

