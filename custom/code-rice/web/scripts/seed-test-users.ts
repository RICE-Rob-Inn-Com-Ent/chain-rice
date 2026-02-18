/**
 * Seed test users for Code-Rice with role-prefixed IDs
 * 
 * Usage: tsx scripts/seed-test-users.ts
 * 
 * Creates test users for each role:
 * - DEV (Developer)
 * - ADM (Admin)
 * - MGR (Manager)
 * - OWN (Owner)
 */

import { generateUserId } from "../lib/user-id-generator";
import { hashPassword } from "../lib/auth";
import { query, queryOne } from "../lib/db";

interface TestUser {
  email: string;
  password: string;
  name: string;
  role: string;
}

const TEST_USERS: TestUser[] = [
  {
    email: process.env.TEST_USER_DEV_EMAIL || "dev@code-rice.test",
    password: process.env.TEST_USER_DEV_PASSWORD || "test123",
    name: process.env.TEST_USER_DEV_NAME || "Test Developer",
    role: "developer",
  },
  {
    email: process.env.TEST_USER_ADM_EMAIL || "adm@code-rice.test",
    password: process.env.TEST_USER_ADM_PASSWORD || "test123",
    name: process.env.TEST_USER_ADM_NAME || "Test Admin",
    role: "admin",
  },
  {
    email: process.env.TEST_USER_MGR_EMAIL || "mgr@code-rice.test",
    password: process.env.TEST_USER_MGR_PASSWORD || "test123",
    name: process.env.TEST_USER_MGR_NAME || "Test Manager",
    role: "manager",
  },
  {
    email: process.env.TEST_USER_OWN_EMAIL || "own@code-rice.test",
    password: process.env.TEST_USER_OWN_PASSWORD || "test123",
    name: process.env.TEST_USER_OWN_NAME || "Test Owner",
    role: "owner",
  },
];

async function seedTestUsers() {
  console.log("🌱 Seeding test users for Code-Rice...\n");

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

      // Hash password
      const passwordHash = await hashPassword(testUser.password);

      // Parse name into first and last
      const nameParts = testUser.name.split(" ");
      const firstName = nameParts[0] || null;
      const lastName = nameParts.slice(1).join(" ") || null;

      // Create user
      await query(
        `INSERT INTO users (
          id, email, display_name, first_name, last_name, password_hash, 
          email_verified, active, created_at
        ) VALUES ($1, $2, $3, $4, $5, $6, true, true, CURRENT_TIMESTAMP)`,
        [
          userId,
          testUser.email.toLowerCase(),
          testUser.name,
          firstName,
          lastName,
          passwordHash,
        ]
      );

      console.log(`✅ Created ${testUser.role} user: ${testUser.email} (${userId})`);
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


