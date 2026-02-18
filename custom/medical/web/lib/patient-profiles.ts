import { query, queryOne } from "@/lib/db";
import { isValidUserId } from "./user-id-generator";

export type PatientProfilePayload = {
  peselStatus?: string | null;
  childNumber?: string | null;
  gender?: string | null;
  nfzBranch?: string | null;
  insuranceEntitlement?: string | null;
  insuranceConfirmationStatus?: string | null;
  additionalEntitlements?: string | null;
  ekuNumber?: string | null;
  euPatientNumber?: string | null;
  maidenName?: string | null;
  fatherName?: string | null;
  motherName?: string | null;
  authorizedPerson?: string | null;
  documentsInfo?: string | null;
  consentAccepted?: boolean | null;
  dateOfBirth?: string | null;
  pesel?: string | null;
  // Medical history
  allergies?: string | null;
  asthma?: boolean | null;
  jaundice?: string | null;
  hypertension?: string | null;
  heartDiseases?: boolean | null;
  kidneyDiseases?: boolean | null;
  diabetes?: boolean | null;
  tuberculosis?: boolean | null;
  rheumaticDisease?: boolean | null;
  bloodClottingDisorders?: boolean | null;
  hormonalDisorders?: boolean | null;
  porphyria?: boolean | null;
  thyroidDiseases?: boolean | null;
  otherDiseases?: string | null;
  currentMedications?: string | null;
  treatmentConsent?: boolean | null;
};

export async function ensurePatientProfilesTable() {
  try {
    // First, create table if it doesn't exist (without FK constraint)
    // Use VARCHAR(50) for user_id to support role-based IDs
    await query(`
      CREATE TABLE IF NOT EXISTS patient_profiles (
        user_id VARCHAR(50) PRIMARY KEY,
      pesel_status VARCHAR(50),
      child_number VARCHAR(50),
      gender VARCHAR(20),
      nfz_branch VARCHAR(150),
      insurance_entitlement VARCHAR(150),
      insurance_confirmation_status VARCHAR(50),
      insurance_additional_entitlements VARCHAR(150),
      eku_number VARCHAR(150),
      eu_patient_number VARCHAR(150),
      documents_info TEXT,
      maiden_name VARCHAR(150),
      father_name VARCHAR(150),
      mother_name VARCHAR(150),
      authorized_person VARCHAR(200),
      consent_accepted BOOLEAN DEFAULT false,
      -- Medical history
      allergies TEXT,
      asthma BOOLEAN DEFAULT false,
      jaundice VARCHAR(100),
      hypertension VARCHAR(100),
      heart_diseases BOOLEAN DEFAULT false,
      kidney_diseases BOOLEAN DEFAULT false,
      diabetes BOOLEAN DEFAULT false,
      tuberculosis BOOLEAN DEFAULT false,
      rheumatic_disease BOOLEAN DEFAULT false,
      blood_clotting_disorders BOOLEAN DEFAULT false,
      hormonal_disorders BOOLEAN DEFAULT false,
      porphyria BOOLEAN DEFAULT false,
      thyroid_diseases BOOLEAN DEFAULT false,
      other_diseases TEXT,
      current_medications TEXT,
      treatment_consent BOOLEAN DEFAULT false,
      raw_payload JSONB,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
      CREATE INDEX IF NOT EXISTS idx_patient_profiles_user_id ON patient_profiles(user_id);
    `);
    
    // Now add foreign key constraint if it doesn't exist
    try {
      const fkExists = await queryOne<{ exists: boolean }>(
        `SELECT EXISTS (
          SELECT 1 FROM information_schema.table_constraints 
          WHERE table_schema = 'public' 
            AND table_name = 'patient_profiles' 
            AND constraint_name = 'patient_profiles_user_id_fkey'
            AND constraint_type = 'FOREIGN KEY'
        ) as exists`
      );
      
      if (!fkExists?.exists) {
        console.log("Adding foreign key constraint to patient_profiles...");
        // Check if users.id is VARCHAR or UUID and adjust accordingly
        const usersIdType = await queryOne<{ data_type: string }>(
          `SELECT data_type FROM information_schema.columns 
           WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'id'`
        );
        
        if (usersIdType?.data_type === 'character varying' || usersIdType?.data_type === 'varchar') {
          // Users table already uses VARCHAR
          await query(`
            ALTER TABLE patient_profiles
            ADD CONSTRAINT patient_profiles_user_id_fkey
            FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
          `);
        } else {
          // Users table still uses UUID - need to migrate first
          console.log("⚠️  Users table still uses UUID. Please run migration first.");
          throw new Error("Users table must be migrated to VARCHAR before adding foreign key");
        }
        console.log("✅ Foreign key constraint added successfully");
      } else {
        console.log("✅ Foreign key constraint already exists");
      }
    } catch (fkError: any) {
      // If constraint already exists or other error, log and continue
      if (fkError.message.includes("already exists") || fkError.message.includes("duplicate")) {
        console.log("Foreign key constraint already exists (OK)");
      } else {
        console.error("Error adding foreign key constraint:", fkError.message);
        // Don't throw - table exists, constraint might be added manually
      }
    }
  } catch (error: any) {
    // If table already exists or other error, continue
    console.log("Patient profiles table check:", error.message);
  }
  
  // Add medical history columns if they don't exist (migration)
  try {
    await query(`
    DO $$
    BEGIN
      IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'patient_profiles' AND column_name = 'allergies') THEN
        ALTER TABLE patient_profiles ADD COLUMN allergies TEXT;
        ALTER TABLE patient_profiles ADD COLUMN asthma BOOLEAN DEFAULT false;
        ALTER TABLE patient_profiles ADD COLUMN jaundice VARCHAR(100);
        ALTER TABLE patient_profiles ADD COLUMN hypertension VARCHAR(100);
        ALTER TABLE patient_profiles ADD COLUMN heart_diseases BOOLEAN DEFAULT false;
        ALTER TABLE patient_profiles ADD COLUMN kidney_diseases BOOLEAN DEFAULT false;
        ALTER TABLE patient_profiles ADD COLUMN diabetes BOOLEAN DEFAULT false;
        ALTER TABLE patient_profiles ADD COLUMN tuberculosis BOOLEAN DEFAULT false;
        ALTER TABLE patient_profiles ADD COLUMN rheumatic_disease BOOLEAN DEFAULT false;
        ALTER TABLE patient_profiles ADD COLUMN blood_clotting_disorders BOOLEAN DEFAULT false;
        ALTER TABLE patient_profiles ADD COLUMN hormonal_disorders BOOLEAN DEFAULT false;
        ALTER TABLE patient_profiles ADD COLUMN porphyria BOOLEAN DEFAULT false;
        ALTER TABLE patient_profiles ADD COLUMN thyroid_diseases BOOLEAN DEFAULT false;
        ALTER TABLE patient_profiles ADD COLUMN other_diseases TEXT;
        ALTER TABLE patient_profiles ADD COLUMN current_medications TEXT;
        ALTER TABLE patient_profiles ADD COLUMN treatment_consent BOOLEAN DEFAULT false;
      END IF;
    END $$;
    `);
  } catch (error: any) {
    // Columns might already exist
    console.log("Patient profiles columns migration:", error.message);
  }
}

async function userColumnExists(column: string): Promise<boolean> {
  const result = await queryOne<{ exists: boolean }>(
    `
      SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_schema = 'public' AND table_name = 'users' AND column_name = $1
      ) as exists
    `,
    [column]
  );
  return !!result?.exists;
}

export async function safeUpdateUserColumns(
  userId: string,
  updates: Record<string, any>
) {
  const entries = Object.entries(updates).filter(
    ([, value]) => value !== undefined && value !== null
  );
  if (entries.length === 0) return;

  for (const [column, value] of entries) {
    const exists = await userColumnExists(column);
    if (!exists) continue;
    await query(
      `
        UPDATE users
        SET ${column} = $1,
            updated_at = CURRENT_TIMESTAMP
        WHERE id = $2
      `,
      [value, userId]
    );
  }
}

export async function upsertPatientProfile(userId: string, payload?: PatientProfilePayload | null) {
  if (!userId || !payload) {
    console.log("upsertPatientProfile: skipping - userId or payload missing", { userId: !!userId, payload: !!payload });
    return;
  }
  
  // Validate user ID format (accepts both UUID and new format for backward compatibility)
  if (!isValidUserId(userId)) {
    throw new Error(`Invalid user ID format: ${userId}. Expected format: UUID or PREFIX-YYYYMMDD-HHMMSS-XXXXXX`);
  }
  
  try {
    // First, verify that the user exists in the users table
    console.log("upsertPatientProfile: Checking if user exists", { userId, userIdType: typeof userId });
    // Cast to text to support both UUID and VARCHAR columns
    const userExists = await queryOne<{ exists: boolean }>(
      `SELECT EXISTS(SELECT 1 FROM users WHERE id::text = $1) as exists`,
      [userId]
    );
    
    if (!userExists?.exists) {
      // Try to get more info about why it failed
      const allUsers = await query(`SELECT id, email FROM users LIMIT 5`);
      console.error("User not found. Sample users in DB:", allUsers);
      throw new Error(`User with id ${userId} does not exist in the users table`);
    }
    
    console.log("upsertPatientProfile: User exists, proceeding with profile upsert", { userId });
    
    await ensurePatientProfilesTable();

  const normalized = {
    peselStatus: payload.peselStatus || null,
    childNumber: payload.childNumber || null,
    gender: payload.gender || null,
    nfzBranch: payload.nfzBranch || null,
    insuranceEntitlement: payload.insuranceEntitlement || null,
    insuranceConfirmationStatus: payload.insuranceConfirmationStatus || null,
    additionalEntitlements: payload.additionalEntitlements || null,
    ekuNumber: payload.ekuNumber || null,
    euPatientNumber: payload.euPatientNumber || null,
    maidenName: payload.maidenName || null,
    fatherName: payload.fatherName || null,
    motherName: payload.motherName || null,
    authorizedPerson: payload.authorizedPerson || null,
    documentsInfo: payload.documentsInfo || null,
    consentAccepted: payload.consentAccepted ?? false,
    // Medical history
    allergies: payload.allergies || null,
    asthma: payload.asthma ?? false,
    jaundice: payload.jaundice || null,
    hypertension: payload.hypertension || null,
    heartDiseases: payload.heartDiseases ?? false,
    kidneyDiseases: payload.kidneyDiseases ?? false,
    diabetes: payload.diabetes ?? false,
    tuberculosis: payload.tuberculosis ?? false,
    rheumaticDisease: payload.rheumaticDisease ?? false,
    bloodClottingDisorders: payload.bloodClottingDisorders ?? false,
    hormonalDisorders: payload.hormonalDisorders ?? false,
    porphyria: payload.porphyria ?? false,
    thyroidDiseases: payload.thyroidDiseases ?? false,
    otherDiseases: payload.otherDiseases || null,
    currentMedications: payload.currentMedications || null,
    treatmentConsent: payload.treatmentConsent ?? false,
  };

  console.log("upsertPatientProfile: Executing INSERT/UPDATE query", { userId, normalizedKeys: Object.keys(normalized) });
  
  await query(
    `
      INSERT INTO patient_profiles (
        user_id,
        pesel_status,
        child_number,
        gender,
        nfz_branch,
        insurance_entitlement,
        insurance_confirmation_status,
        insurance_additional_entitlements,
        eku_number,
        eu_patient_number,
        documents_info,
        maiden_name,
        father_name,
        mother_name,
        authorized_person,
        consent_accepted,
        allergies,
        asthma,
        jaundice,
        hypertension,
        heart_diseases,
        kidney_diseases,
        diabetes,
        tuberculosis,
        rheumatic_disease,
        blood_clotting_disorders,
        hormonal_disorders,
        porphyria,
        thyroid_diseases,
        other_diseases,
        current_medications,
        treatment_consent,
        raw_payload,
        created_at,
        updated_at
      )
      VALUES (
        $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15,$16,$17,$18,$19,$20,$21,$22,$23,$24,$25,$26,$27,$28,$29,$30,$31,$32,$33,CURRENT_TIMESTAMP,CURRENT_TIMESTAMP
      )
      ON CONFLICT (user_id) DO UPDATE SET
        pesel_status = EXCLUDED.pesel_status,
        child_number = EXCLUDED.child_number,
        gender = EXCLUDED.gender,
        nfz_branch = EXCLUDED.nfz_branch,
        insurance_entitlement = EXCLUDED.insurance_entitlement,
        insurance_confirmation_status = EXCLUDED.insurance_confirmation_status,
        insurance_additional_entitlements = EXCLUDED.insurance_additional_entitlements,
        eku_number = EXCLUDED.eku_number,
        eu_patient_number = EXCLUDED.eu_patient_number,
        documents_info = EXCLUDED.documents_info,
        maiden_name = EXCLUDED.maiden_name,
        father_name = EXCLUDED.father_name,
        mother_name = EXCLUDED.mother_name,
        authorized_person = EXCLUDED.authorized_person,
        consent_accepted = EXCLUDED.consent_accepted,
        allergies = EXCLUDED.allergies,
        asthma = EXCLUDED.asthma,
        jaundice = EXCLUDED.jaundice,
        hypertension = EXCLUDED.hypertension,
        heart_diseases = EXCLUDED.heart_diseases,
        kidney_diseases = EXCLUDED.kidney_diseases,
        diabetes = EXCLUDED.diabetes,
        tuberculosis = EXCLUDED.tuberculosis,
        rheumatic_disease = EXCLUDED.rheumatic_disease,
        blood_clotting_disorders = EXCLUDED.blood_clotting_disorders,
        hormonal_disorders = EXCLUDED.hormonal_disorders,
        porphyria = EXCLUDED.porphyria,
        thyroid_diseases = EXCLUDED.thyroid_diseases,
        other_diseases = EXCLUDED.other_diseases,
        current_medications = EXCLUDED.current_medications,
        treatment_consent = EXCLUDED.treatment_consent,
        raw_payload = EXCLUDED.raw_payload,
        updated_at = CURRENT_TIMESTAMP
    `,
    [
      userId,
      normalized.peselStatus,
      normalized.childNumber,
      normalized.gender,
      normalized.nfzBranch,
      normalized.insuranceEntitlement,
      normalized.insuranceConfirmationStatus,
      normalized.additionalEntitlements,
      normalized.ekuNumber,
      normalized.euPatientNumber,
      normalized.documentsInfo,
      normalized.maidenName,
      normalized.fatherName,
      normalized.motherName,
      normalized.authorizedPerson,
      normalized.consentAccepted,
      normalized.allergies,
      normalized.asthma,
      normalized.jaundice,
      normalized.hypertension,
      normalized.heartDiseases,
      normalized.kidneyDiseases,
      normalized.diabetes,
      normalized.tuberculosis,
      normalized.rheumaticDisease,
      normalized.bloodClottingDisorders,
      normalized.hormonalDisorders,
      normalized.porphyria,
      normalized.thyroidDiseases,
      normalized.otherDiseases,
      normalized.currentMedications,
      normalized.treatmentConsent,
      JSON.stringify(payload),
    ]
  );
  
  console.log("upsertPatientProfile: Query executed successfully");

    await safeUpdateUserColumns(userId, {
      pesel: payload.pesel || null,
      date_of_birth: payload.dateOfBirth || null,
    });

    // Sync to MongoDB for faster queries (optional, doesn't fail if MongoDB is unavailable)
    try {
      const { syncPatientProfileToMongoDB } = await import("../prisma/migrate-to-both-dbs");
      await syncPatientProfileToMongoDB(userId, {
        ...normalized,
        pesel: payload.pesel || null,
        dateOfBirth: payload.dateOfBirth || null,
      });
    } catch (mongoError: any) {
      console.log("MongoDB sync failed (non-critical):", mongoError.message);
    }
  } catch (error: any) {
    console.error("Error in upsertPatientProfile:", error);
    throw new Error(`Failed to save patient profile: ${error.message}`);
  }
}


