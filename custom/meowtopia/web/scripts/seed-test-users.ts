/**
 * Seed test users and foundations for Meowtopia with role-prefixed IDs
 * 
 * Usage: tsx scripts/seed-test-users.ts
 * 
 * Creates test users for each role:
 * - CUS (Customer)
 * - MGR (Manager)
 * - ADM (Admin)
 * - OWN (Owner)
 * - ART (Artist)
 * 
 * Creates test foundations:
 * - Fundacja Koty w Potrzebie
 * - Schronisko dla Zwierząt
 * - Ratujemy Zwierzęta
 */

// Set Prisma engine BEFORE any imports (to override lib/prisma.ts which sets musl for Alpine)
// We're on a glibc system (Arch/Debian/Ubuntu), so prefer debian binary
const _path = require("path");
const _fs = require("fs");
const _debianPath = _path.join(__dirname, "../node_modules/.prisma/client/libquery_engine-debian-openssl-3.0.x.so.node");
const _muslPath = _path.join(__dirname, "../node_modules/.prisma/client/libquery_engine-linux-musl-openssl-3.0.x.so.node");
if (_fs.existsSync(_debianPath)) {
  process.env.PRISMA_QUERY_ENGINE_LIBRARY = _debianPath;
} else if (_fs.existsSync(_muslPath)) {
  process.env.PRISMA_QUERY_ENGINE_LIBRARY = _muslPath;
}

// Load environment variables FIRST, before importing Prisma
import { config } from "dotenv";
import { resolve } from "path";
import { readFileSync } from "fs";

// Load .env.local
const envPath = resolve(__dirname, "../.env.local");
const envResult = config({ path: envPath });

// If dotenv didn't load DATABASE_URL, read it directly from file
if (!process.env.DATABASE_URL) {
  try {
    const envContent = readFileSync(envPath, "utf-8");
    const dbUrlMatch = envContent.match(/^DATABASE_URL=(.+)$/m);
    if (dbUrlMatch) {
      process.env.DATABASE_URL = dbUrlMatch[1].trim();
    }
  } catch (e) {
    console.warn("Could not read DATABASE_URL from .env.local:", e);
  }
}

console.log("DATABASE_URL:", process.env.DATABASE_URL ? "✓ Set" : "✗ Missing");

// Now import Prisma after environment is set up
import { generateUserId } from "../lib/user-id-generator";
import { prisma } from "../lib/prisma";
import bcrypt from "bcryptjs";

interface TestUser {
  email: string;
  password: string;
  name: string;
  role: "CUSTOMER" | "VOLUNTEER" | "MANAGER" | "ADMIN" | "OWNER" | "ARTIST";
  rolePrefix: string; // For generating user ID
}

const TEST_USERS: TestUser[] = [
  {
    email: process.env.TEST_USER_CUS_EMAIL || "cus@meowtopia.test",
    password: process.env.TEST_USER_CUS_PASSWORD || "test123",
    name: process.env.TEST_USER_CUS_NAME || "Test Customer",
    role: "CUSTOMER",
    rolePrefix: "CUS",
  },
  {
    email: process.env.TEST_USER_MGR_EMAIL || "mgr@meowtopia.test",
    password: process.env.TEST_USER_MGR_PASSWORD || "test123",
    name: process.env.TEST_USER_MGR_NAME || "Test Manager",
    role: "MANAGER",
    rolePrefix: "MGR",
  },
  {
    email: process.env.TEST_USER_ADM_EMAIL || "adm@meowtopia.test",
    password: process.env.TEST_USER_ADM_PASSWORD || "test123",
    name: process.env.TEST_USER_ADM_NAME || "Test Admin",
    role: "ADMIN",
    rolePrefix: "ADM",
  },
  {
    email: process.env.TEST_USER_OWN_EMAIL || "own@meowtopia.test",
    password: process.env.TEST_USER_OWN_PASSWORD || "test123",
    name: process.env.TEST_USER_OWN_NAME || "Test Owner",
    role: "OWNER",
    rolePrefix: "OWN",
  },
  {
    email: process.env.TEST_USER_ART_EMAIL || "art@meowtopia.test",
    password: process.env.TEST_USER_ART_PASSWORD || "test123",
    name: process.env.TEST_USER_ART_NAME || "Test Artist",
    role: "ARTIST",
    rolePrefix: "ART",
  },
];

interface TestFoundation {
  email: string;
  password: string;
  name: string;
  description: string;
  website?: string;
}

const TEST_FOUNDATIONS: TestFoundation[] = [
  {
    email: process.env.TEST_FOUNDATION_1_EMAIL || "fundacja1@meowtopia.test",
    password: process.env.TEST_FOUNDATION_1_PASSWORD || "test123",
    name: "Fundacja Koty w Potrzebie",
    description: "Fundacja pomagająca kotom w potrzebie",
    website: "https://koty-w-potrzebie.pl",
  },
  {
    email: process.env.TEST_FOUNDATION_2_EMAIL || "fundacja2@meowtopia.test",
    password: process.env.TEST_FOUNDATION_2_PASSWORD || "test123",
    name: "Schronisko dla Zwierząt",
    description: "Schronisko dla bezdomnych zwierząt",
    website: "https://schronisko-zwierzeta.pl",
  },
  {
    email: process.env.TEST_FOUNDATION_3_EMAIL || "fundacja3@meowtopia.test",
    password: process.env.TEST_FOUNDATION_3_PASSWORD || "test123",
    name: "Ratujemy Zwierzęta",
    description: "Organizacja ratująca zwierzęta w potrzebie",
    website: "https://ratujemy-zwierzeta.pl",
  },
];

async function seedTestUsers() {
  console.log("🌱 Seeding test users for Meowtopia...\n");

  for (const testUser of TEST_USERS) {
    try {
      // Check if user already exists
      const existing = await prisma.user.findUnique({
        where: { email: testUser.email.toLowerCase() },
      });

      if (existing) {
        console.log(`⏭️  User ${testUser.email} already exists, skipping...`);
        continue;
      }

      // Generate role-prefixed user ID
      const userId = await generateUserId(testUser.rolePrefix as any);
      console.log(`📝 Generating ID for ${testUser.role} (${testUser.rolePrefix}): ${userId}`);

      // Hash password
      const passwordHash = await bcrypt.hash(testUser.password, 12);

      // Parse name into first and last
      const nameParts = testUser.name.split(" ");
      const firstName = nameParts[0] || "";
      const lastName = nameParts.slice(1).join(" ") || "";

      // Generate username from email (before @) or use a default
      const emailPrefix = testUser.email.split("@")[0];
      const username = `${testUser.rolePrefix.toLowerCase()}_${emailPrefix}`;
      
      // Create user with Prisma
      await prisma.user.create({
        data: {
          id: userId,
          email: testUser.email.toLowerCase(),
          username: username,
          name: testUser.name,
          firstName: firstName || null,
          lastName: lastName || null,
          passwordHash: passwordHash,
          role: testUser.role,
          emailVerified: new Date(),
        },
      });

      console.log(`✅ Created ${testUser.role} user: ${testUser.email} (${userId})`);
    } catch (error) {
      console.error(`❌ Error creating user ${testUser.email}:`, error);
    }
  }

  console.log("\n✨ Test users seeding completed!");
  console.log("\n📋 Test Users:");
  TEST_USERS.forEach((user) => {
    console.log(`   ${user.role}: ${user.email} / ${user.password}`);
  });
}

async function seedTestFoundations() {
  console.log("\n🌱 Seeding test foundations for Meowtopia...\n");

  for (const foundation of TEST_FOUNDATIONS) {
    try {
      // Check if foundation already exists
      const existing = await prisma.foundation.findUnique({
        where: { email: foundation.email.toLowerCase() },
      });

      if (existing) {
        console.log(`⏭️  Foundation ${foundation.email} already exists, skipping...`);
        continue;
      }

      // Hash password
      const passwordHash = await bcrypt.hash(foundation.password, 12);

      // Create foundation with Prisma
      const created = await prisma.foundation.create({
        data: {
          name: foundation.name,
          description: foundation.description,
          email: foundation.email.toLowerCase(),
          passwordHash: passwordHash,
          website: foundation.website || null,
          active: true,
          featured: false,
          totalReceived: 0,
        },
      });

      console.log(`✅ Created foundation: ${foundation.name} (${foundation.email})`);
    } catch (error) {
      console.error(`❌ Error creating foundation ${foundation.email}:`, error);
    }
  }

  console.log("\n✨ Test foundations seeding completed!");
  console.log("\n📋 Test Foundations:");
  TEST_FOUNDATIONS.forEach((foundation) => {
    console.log(`   ${foundation.name}: ${foundation.email} / ${foundation.password}`);
  });
}

async function seedAll() {
  await seedTestUsers();
  await seedTestFoundations();
}

// Run if executed directly
if (require.main === module) {
  seedAll()
    .then(() => {
      console.log("\n✅ Done!");
      process.exit(0);
    })
    .catch((error) => {
      console.error("\n❌ Error:", error);
      process.exit(1);
    });
}

export { seedTestUsers, seedTestFoundations, seedAll };


