/**
 * Seed test users for Ceramix with role-prefixed IDs
 * 
 * Usage: tsx scripts/seed-test-users.ts
 * 
 * Creates test users for each role:
 * - PAT (Patient)
 * - DOC (Doctor)
 * - ADM (Admin)
 * - OWN (Owner)
 */

import { generateUserId } from "../lib/user-id-generator";
import { hashPassword } from "../lib/auth";
import { generateUsername } from "../lib/username-utils";
import { query, queryOne } from "../lib/db";

interface TestUser {
  email: string;
  password: string;
  name: string;
  role: string;
}

const TEST_USERS: TestUser[] = [
  {
    email: process.env.TEST_USER_PAT_EMAIL || "pat@ceramix.test",
    password: process.env.TEST_USER_PAT_PASSWORD || "test123",
    name: process.env.TEST_USER_PAT_NAME || "Test Patient",
    role: "patient",
  },
  {
    email: process.env.TEST_USER_DOC_EMAIL || "doc@ceramix.test",
    password: process.env.TEST_USER_DOC_PASSWORD || "test123",
    name: process.env.TEST_USER_DOC_NAME || "Test Doctor",
    role: "doctor",
  },
  {
    email: process.env.TEST_USER_ADM_EMAIL || "adm@ceramix.test",
    password: process.env.TEST_USER_ADM_PASSWORD || "test123",
    name: process.env.TEST_USER_ADM_NAME || "Test Admin",
    role: "admin",
  },
  {
    email: process.env.TEST_USER_OWN_EMAIL || "own@ceramix.test",
    password: process.env.TEST_USER_OWN_PASSWORD || "test123",
    name: process.env.TEST_USER_OWN_NAME || "Test Owner",
    role: "owner",
  },
];

async function seedTestUsers() {
  console.log("🌱 Seeding test users for Ceramix...\n");

  for (const testUser of TEST_USERS) {
    try {
      // Check if user already exists
      const existing = await queryOne<{ id: string }>(
        `SELECT id FROM users WHERE email = $1`,
        [testUser.email.toLowerCase()]
      );

      if (existing) {
        console.log(`⏭️  User ${testUser.email} already exists, skipping...`);
        continue;
      }

      // Generate role-prefixed user ID
      const userId = await generateUserId(testUser.role);
      console.log(`📝 Generating ID for ${testUser.role}: ${userId}`);

      // Generate username from email (part before @) - generateUsername will prevent reserved prefixes
      const username = await generateUsername(testUser.email.split('@')[0] || testUser.name);
      console.log(`📝 Generated username: ${username}`);

      // Hash password
      const passwordHash = await hashPassword(testUser.password);

      // Create user with username
      await query(
        `INSERT INTO users (
          id, username, email, display_name, password_hash, 
          email_verified, active, account_state, created_at
        ) VALUES ($1, $2, $3, $4, $5, true, true, 'ACTIVE', CURRENT_TIMESTAMP)`,
        [userId, username, testUser.email.toLowerCase(), testUser.name, passwordHash]
      );

      console.log(`✅ Created ${testUser.role} user: ${testUser.email} (${userId}, username: ${username})`);
    } catch (error) {
      console.error(`❌ Error creating user ${testUser.email}:`, error);
    }
  }

  console.log("\n✨ Test users seeding completed!");
  console.log("\n📋 Test Users:");
  TEST_USERS.forEach((user) => {
    console.log(`   ${user.role.toUpperCase()}: ${user.email} / ${user.password}`);
  });
}

// Run if executed directly
if (require.main === module) {
  seedTestUsers()
    .then(() => {
      console.log("\n✅ Done!");
      process.exit(0);
    })
    .catch((error) => {
      console.error("\n❌ Error:", error);
      process.exit(1);
    });
}

export { seedTestUsers };


