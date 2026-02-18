/**
 * Direct verification of foreign key constraint
 */

import { query, queryOne } from "../lib/db";

async function verifyFK() {
  console.log("🔍 Direct verification of foreign key constraint...\n");

  try {
    // Method 1: Check pg_constraint directly
    console.log("Method 1: Checking pg_constraint...");
    const pgConstraint = await query(`
      SELECT 
        conname as constraint_name,
        conrelid::regclass as table_name,
        confrelid::regclass as foreign_table_name
      FROM pg_constraint
      WHERE conrelid = 'patient_profiles'::regclass
        AND contype = 'f'
    `);

    if (pgConstraint.rows.length > 0) {
      console.log("   ✅ Foreign key constraints found:");
      pgConstraint.rows.forEach((fk: any) => {
        console.log(`   - ${fk.constraint_name}: ${fk.table_name} -> ${fk.foreign_table_name}`);
      });
    } else {
      console.log("   ❌ No foreign key constraints found in pg_constraint");
    }
    console.log();

    // Method 2: Try to get constraint details
    console.log("Method 2: Getting constraint details...");
    const constraintDetails = await query(`
      SELECT
        tc.constraint_name,
        tc.table_name,
        kcu.column_name,
        ccu.table_name AS foreign_table_name,
        ccu.column_name AS foreign_column_name
      FROM information_schema.table_constraints AS tc
      JOIN information_schema.key_column_usage AS kcu
        ON tc.constraint_name = kcu.constraint_name
        AND tc.table_schema = kcu.table_schema
      JOIN information_schema.constraint_column_usage AS ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
      WHERE tc.table_schema = 'public'
        AND tc.table_name = 'patient_profiles'
        AND tc.constraint_type = 'FOREIGN KEY'
    `);

    if (constraintDetails.rows.length > 0) {
      console.log("   ✅ Foreign key constraints found:");
      constraintDetails.rows.forEach((fk: any) => {
        console.log(`   - ${fk.constraint_name}: ${fk.column_name} -> ${fk.foreign_table_name}.${fk.foreign_column_name}`);
      });
    } else {
      console.log("   ❌ No foreign key constraints found in information_schema");
    }
    console.log();

    // Method 3: Try to add constraint if it doesn't exist
    console.log("Method 3: Attempting to add constraint if missing...");
    try {
      await query(`
        DO $$
        BEGIN
          IF NOT EXISTS (
            SELECT 1 FROM pg_constraint 
            WHERE conrelid = 'patient_profiles'::regclass 
            AND contype = 'f'
            AND conname = 'patient_profiles_user_id_fkey'
          ) THEN
            ALTER TABLE patient_profiles
            ADD CONSTRAINT patient_profiles_user_id_fkey
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE;
            RAISE NOTICE 'Foreign key constraint added';
          ELSE
            RAISE NOTICE 'Foreign key constraint already exists';
          END IF;
        END $$;
      `);
      console.log("   ✅ Constraint check/add completed");
    } catch (error: any) {
      console.log(`   ⚠️  Error: ${error.message}`);
    }

  } catch (error: any) {
    console.error("❌ Error:", error);
  }
}

verifyFK()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });




















