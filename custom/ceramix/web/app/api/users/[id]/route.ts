import { NextRequest, NextResponse } from "next/server";
import { getCurrentUser } from "@/lib/auth";
import { query, queryOne } from "@/lib/db";
import { hashPassword } from "@/lib/auth";
import { upsertPatientProfile, PatientProfilePayload } from "@/lib/patient-profiles";
import { isValidUserId, getRoleFromId, generateUserId, getRolePrefix } from "@/lib/user-id-generator";
import { isOwner } from "@/lib/rbac";

// GET - Szczegóły użytkownika
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await getCurrentUser();
    if (!user || !isOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const targetUser = await queryOne<{ id: string; username: string; [key: string]: any }>(
      `SELECT u.* FROM users u WHERE u.id::text = $1`,
      [params.id]
    );
    
    if (targetUser) {
      // Add role from ID prefix
      targetUser.role = getRoleFromId(targetUser.id) || "user";
    }

    if (!targetUser) {
      return NextResponse.json({ error: "Użytkownik nie znaleziony" }, { status: 404 });
    }

    return NextResponse.json({ user: targetUser });
  } catch (error: any) {
    console.error("Get user error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// PUT - Aktualizuj użytkownika
export async function PUT(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await getCurrentUser();
    if (!user || !isOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Validate user ID format (accepts both UUID and new format for backward compatibility)
    if (!isValidUserId(params.id)) {
      return NextResponse.json({ 
        error: `Nieprawidłowy format ID użytkownika: ${params.id}. Oczekiwany format: UUID lub PREFIX-YYYYMMDD-HHMMSS-XXXXXX` 
      }, { status: 400 });
    }

    const body = await request.json();
    const {
      email,
      password,
      displayName,
      firstName,
      lastName,
      phone,
      role,
      active,
      emailVerified,
      patientProfile,
      username,
    } = body;

    // Aktualizuj podstawowe dane
    const updates: string[] = [];
    const params_list: any[] = [];
    let paramIndex = 1;

    if (email !== undefined) {
      updates.push(`email = $${paramIndex}`);
      params_list.push(email.toLowerCase());
      paramIndex++;
    }

    if (password) {
      const passwordHash = await hashPassword(password);
      updates.push(`password_hash = $${paramIndex}`);
      params_list.push(passwordHash);
      paramIndex++;
    }

    if (displayName !== undefined) {
      updates.push(`display_name = $${paramIndex}`);
      params_list.push(displayName);
      paramIndex++;
    }

    if (firstName !== undefined) {
      updates.push(`first_name = $${paramIndex}`);
      params_list.push(firstName);
      paramIndex++;
    }

    if (lastName !== undefined) {
      updates.push(`last_name = $${paramIndex}`);
      params_list.push(lastName);
      paramIndex++;
    }

    if (active !== undefined) {
      updates.push(`active = $${paramIndex}`);
      params_list.push(active);
      paramIndex++;
    }

    if (emailVerified !== undefined) {
      updates.push(`email_verified = $${paramIndex}`);
      params_list.push(emailVerified);
      paramIndex++;
    }

    updates.push(`updated_at = CURRENT_TIMESTAMP`);
    params_list.push(params.id);

    if (updates.length > 1) {
      await query(
        `UPDATE users SET ${updates.join(", ")} WHERE id = $${paramIndex}`,
        params_list
      );
    }

    // Aktualizuj telefon jeśli podany
    if (phone !== undefined) {
      // Sprawdź czy istnieje kolumna phone w users
      const hasUsersPhone = await queryOne(
        `SELECT EXISTS (
          SELECT 1 FROM information_schema.columns 
          WHERE table_schema = 'public' AND table_name = 'users' AND column_name = 'phone'
        ) as exists`
      );
      
      if (hasUsersPhone?.exists) {
        await query(`UPDATE users SET phone = $1 WHERE id = $2`, [phone, params.id]);
      }
      // Telefon może być również przechowywany w patient_profiles przez upsertPatientProfile
    }

    // Aktualizuj rolę jeśli podana - zmień ID użytkownika na nowy z odpowiednim prefiksem
    if (role) {
      // First, check if user exists with current ID, if not try to find by email or username
      let userIdToUpdate = params.id;
      const userExists = await queryOne<{ exists: boolean }>(
        `SELECT EXISTS(SELECT 1 FROM users WHERE id::text = $1) as exists`,
        [params.id]
      );
      
      if (!userExists?.exists) {
        console.log(`User not found with ID ${params.id}, trying to find by email or username...`);
        
        // Try to find by email from body
        if (email) {
          const userByEmail = await queryOne<{ id: string }>(
            `SELECT id FROM users WHERE email = $1`,
            [email]
          );
          if (userByEmail) {
            userIdToUpdate = userByEmail.id;
            console.log(`Found user by email ${email}: ${userIdToUpdate}`);
          }
        }
        
        // Try to find by username from body
        if (userIdToUpdate === params.id && username) {
          const userByUsername = await queryOne<{ id: string }>(
            `SELECT id FROM users WHERE username = $1`,
            [username]
          );
          if (userByUsername) {
            userIdToUpdate = userByUsername.id;
            console.log(`Found user by username ${username}: ${userIdToUpdate}`);
          }
        }
        
        // If still not found, try to find user by checking sessions or other foreign key tables
        // This handles the case where user was migrated but we don't have email/username in body
        if (userIdToUpdate === params.id) {
          // Extract timestamp part from old ID (format: PREFIX-YYYYMMDD-HHMMSS-XXXXXX)
          // Try to find user with same timestamp but different role prefix
          const idParts = params.id.split('-');
          if (idParts.length >= 3) {
            const timestampPart = idParts.slice(1, 3).join('-'); // YYYYMMDD-HHMMSS
            const sequencePart = idParts[3] || ''; // XXXXXX
            
            // Try to find user with same timestamp and sequence (different role prefix)
            const usersWithSameTimestamp = await query<{ id: string; email: string; username: string }>(
              `SELECT id, email, username FROM users 
               WHERE id::text LIKE $1 
               ORDER BY created_at DESC 
               LIMIT 10`,
              [`%-${timestampPart}-${sequencePart}`]
            );
            
            if (usersWithSameTimestamp.rows.length > 0) {
              // Use the most recent one (should be the current ID)
              userIdToUpdate = usersWithSameTimestamp.rows[0].id;
              console.log(`Found user by timestamp pattern (${timestampPart}-${sequencePart}): ${userIdToUpdate}`);
            } else {
              // Try to find by checking sessions table
              const userFromSession = await queryOne<{ user_id: string }>(
                `SELECT DISTINCT user_id FROM sessions 
                 WHERE user_id::text LIKE $1 
                 ORDER BY created_at DESC 
                 LIMIT 1`,
                [`%-${timestampPart}-%`]
              );
              
              if (userFromSession) {
                userIdToUpdate = userFromSession.user_id;
                console.log(`Found user from sessions: ${userIdToUpdate}`);
              }
            }
          }
        }
        
        if (userIdToUpdate === params.id) {
          throw new Error(`User with ID ${params.id} not found. The user may have been migrated to a new ID. Please refresh the page to get the current user ID.`);
        }
      }
      
      const currentRole = getRoleFromId(userIdToUpdate);
      if (currentRole !== role) {
        // Generate new ID with correct role prefix
        const newId = await generateUserId(role);
        
        // Find all tables with foreign key references to users.id
        const foreignKeyTables = await query<{ table_name: string; column_name: string }>(`
          SELECT 
            tc.table_name,
            kcu.column_name
          FROM information_schema.table_constraints AS tc
          JOIN information_schema.key_column_usage AS kcu
            ON tc.constraint_name = kcu.constraint_name
            AND tc.table_schema = kcu.table_schema
          JOIN information_schema.constraint_column_usage AS ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
          WHERE tc.constraint_type = 'FOREIGN KEY'
            AND ccu.table_name = 'users'
            AND ccu.column_name = 'id'
            AND tc.table_schema = 'public'
        `);
        
        // Update all foreign key references
        // IMPORTANT: Update foreign keys BEFORE updating users.id to avoid constraint violations
        // Use a transaction to ensure all updates happen atomically
        console.log(`Updating foreign keys for user ${userIdToUpdate} -> ${newId}`);
        console.log(`Found ${foreignKeyTables.rows.length} foreign key tables to update`);
        
        // Start transaction
        await query('BEGIN');
        
        try {
          // Strategy: Create new user record with new ID, update foreign keys, then delete old record
          // This avoids foreign key constraint violations
          
          // Step 1: Get current user data
          const currentUser = await queryOne<Record<string, any>>(
            `SELECT * FROM users WHERE id::text = $1`,
            [userIdToUpdate]
          );
          
          if (!currentUser) {
            throw new Error(`User with ID ${userIdToUpdate} not found`);
          }
          
          // Step 2: Temporarily change old user's email and username to make room for new record
          // This allows us to insert new record with original email and username
          const oldEmail = currentUser.email;
          const oldUsername = currentUser.username;
          const timestamp = Date.now();
          const tempEmail = `${oldEmail}.old.${timestamp}@temp`;
          // Username must match: ^[a-z0-9]([a-z0-9-]{1,48}[a-z0-9])?$
          // Use hyphens instead of dots, ensure it starts and ends with alphanumeric
          const tempUsername = `${oldUsername}-old-${timestamp}`.toLowerCase().replace(/[^a-z0-9-]/g, '').substring(0, 50);
          // Ensure it starts and ends with alphanumeric
          const cleanTempUsername = tempUsername.replace(/^-+|-+$/g, '').replace(/-{2,}/g, '-');
          // Ensure minimum length of 3
          const finalTempUsername = cleanTempUsername.length >= 3 ? cleanTempUsername : `temp-${timestamp}`.substring(0, 50);
          
          await query(
            `UPDATE users SET email = $1, username = $2 WHERE id::text = $3`,
            [tempEmail, finalTempUsername, userIdToUpdate]
          );
          console.log(`Temporarily changed old user email to ${tempEmail} and username to ${finalTempUsername}`);
          
          // Step 3: Insert new user record with new ID and same data (including original email and username)
          // Exclude id, created_at, updated_at from the copy (they will be set automatically)
          const { id: oldId, created_at, updated_at, ...userData } = currentUser;
          // Restore original email and username in userData
          userData.email = oldEmail;
          userData.username = oldUsername;
          const columns = Object.keys(userData).filter(col => userData[col] !== undefined);
          const values = columns.map(col => userData[col]);
          const placeholders = values.map((_, i) => `$${i + 2}`).join(', ');
          
          // Build INSERT statement with explicit column list
          const insertColumns = ['id', ...columns].join(', ');
          const insertValues = `$1, ${placeholders}`;
          
          await query(
            `INSERT INTO users (${insertColumns}) VALUES (${insertValues})`,
            [newId, ...values]
          );
          console.log(`Created new user record with ID ${newId} and email ${oldEmail}`);
          
          // Step 3: Update all foreign key references to point to new ID
          for (const fk of foreignKeyTables.rows) {
          try {
            // Check if table exists and has data
            const countResult = await queryOne<{ count: string }>(
              `SELECT COUNT(*)::text as count FROM ${fk.table_name} WHERE ${fk.column_name}::text = $1`,
              [userIdToUpdate]
            );
            
            const rowCount = countResult ? parseInt(countResult.count) : 0;
            
            if (rowCount > 0) {
              console.log(`Found ${rowCount} rows in ${fk.table_name}.${fk.column_name} to update`);
              
              // Get column data type to determine correct casting
              const columnType = await queryOne<{ data_type: string }>(
                `SELECT data_type FROM information_schema.columns 
                 WHERE table_schema = 'public' 
                 AND table_name = $1 
                 AND column_name = $2`,
                [fk.table_name, fk.column_name]
              );
              
              // Use appropriate casting based on column type
              if (columnType?.data_type === 'character varying' || columnType?.data_type === 'text') {
                // VARCHAR/TEXT column - use direct text comparison and update
                await query(
                  `UPDATE ${fk.table_name} SET ${fk.column_name} = $1 WHERE ${fk.column_name}::text = $2`,
                  [newId, userIdToUpdate]
                );
                console.log(`Updated ${rowCount} rows in ${fk.table_name}.${fk.column_name} (VARCHAR)`);
              } else if (columnType?.data_type === 'uuid') {
                // UUID column - cast newId to UUID
                await query(
                  `UPDATE ${fk.table_name} SET ${fk.column_name} = $1::uuid WHERE ${fk.column_name}::text = $2`,
                  [newId, params.id]
                );
                console.log(`Updated ${rowCount} rows in ${fk.table_name}.${fk.column_name} (UUID)`);
              } else {
                // Other type - try text casting
                await query(
                  `UPDATE ${fk.table_name} SET ${fk.column_name} = $1 WHERE ${fk.column_name}::text = $2`,
                  [newId, userIdToUpdate]
                );
                console.log(`Updated ${rowCount} rows in ${fk.table_name}.${fk.column_name} (${columnType?.data_type || 'unknown'})`);
              }
            } else {
              console.log(`No rows to update in ${fk.table_name}.${fk.column_name}`);
            }
          } catch (error: any) {
            console.error(`Error updating ${fk.table_name}.${fk.column_name}:`, error);
            // Don't continue if foreign key update fails - we need all foreign keys updated
            throw new Error(`Failed to update foreign key ${fk.table_name}.${fk.column_name}: ${error.message}`);
          }
        }
        
          console.log(`All foreign keys updated, now deleting old user record`);
          
          // Step 4: Delete old user record (foreign keys now point to new ID)
          await query(
            `DELETE FROM users WHERE id::text = $1`,
            [userIdToUpdate]
          );
          console.log(`Deleted old user record with ID ${userIdToUpdate}`);
          
          // Commit transaction
          await query('COMMIT');
          console.log(`Successfully migrated user from ${userIdToUpdate} to ${newId}`);
          
          // Update params.id for subsequent queries
          params.id = newId;
          
          // Update userIdToUpdate for final user fetch
          userIdToUpdate = newId;
        } catch (error: any) {
          // Rollback on any error
          await query('ROLLBACK');
          console.error('Transaction rolled back due to error:', error);
          throw error;
        }
      }
    }

    // Aktualizuj profil pacjenta jeśli podany
    if (patientProfile) {
      try {
        // Verify user exists before updating profile
        console.log("Checking if user exists:", params.id);
        const userCheck = await queryOne(
          `SELECT id, email, display_name FROM users WHERE id = $1`,
          [params.id]
        );
        
        if (!userCheck) {
          console.error("User not found:", params.id);
          return NextResponse.json({ 
            error: `Użytkownik o ID ${params.id} nie istnieje w bazie danych` 
          }, { status: 404 });
        }
        
        console.log("User found:", userCheck.email, "Proceeding with profile update");
        console.log("Updating patient profile for user:", params.id, "with data:", JSON.stringify(patientProfile).substring(0, 200));
        await upsertPatientProfile(params.id, patientProfile as PatientProfilePayload);
        console.log("Patient profile updated successfully");
      } catch (error: any) {
        console.error("Error updating patient profile:", error);
        console.error("Error stack:", error.stack);
        // Return error to user so they know what went wrong
        return NextResponse.json({ 
          error: `Nie udało się zapisać profilu pacjenta: ${error.message}` 
        }, { status: 500 });
      }
    }

    const updatedUser = await queryOne(
      `SELECT u.* FROM users u WHERE u.id::text = $1`,
      [params.id]
    );
    
    if (updatedUser) {
      // Add role from ID prefix
      updatedUser.role = getRoleFromId(updatedUser.id) || "user";
    }

    return NextResponse.json({ success: true, user: updatedUser });
  } catch (error: any) {
    console.error("Update user error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

// DELETE - Usuń użytkownika
export async function DELETE(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  try {
    const user = await getCurrentUser();
    if (!user || !isOwner(user.id)) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Nie można usunąć siebie
    if (user.id === params.id) {
      return NextResponse.json({ error: "Nie możesz usunąć własnego konta" }, { status: 400 });
    }

    await query(`DELETE FROM users WHERE id = $1`, [params.id]);

    return NextResponse.json({ success: true });
  } catch (error: any) {
    console.error("Delete user error:", error);
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}


