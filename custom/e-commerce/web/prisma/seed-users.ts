/**
 * Seed test users for Meowtopia
 */

// Prisma types - will be available after running: yarn prisma generate
// @ts-ignore - Prisma types not generated yet
import { PrismaClient } from '@prisma/client';
import bcrypt from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  const password = 'Test1234!';
  const hash = await bcrypt.hash(password, 10);

  const users = [
    {
      email: 'superadmin@meowtopia.com',
      name: 'Super Administrator',
      passwordHash: hash,
      role: 'SUPERADMIN' as const,
      emailVerified: new Date(),
    },
    {
      email: 'admin@meowtopia.com',
      name: 'Administrator',
      passwordHash: hash,
      role: 'ADMIN' as const,
      emailVerified: new Date(),
    },
    {
      email: 'manager@meowtopia.com',
      name: 'Manager',
      passwordHash: hash,
      role: 'MANAGER' as const,
      emailVerified: new Date(),
    },
    {
      email: 'user@meowtopia.com',
      name: 'Regular User',
      passwordHash: hash,
      role: 'USER' as const,
      emailVerified: new Date(),
    },
  ];

  for (const userData of users) {
    await prisma.user.upsert({
      where: { email: userData.email },
      update: {
        passwordHash: userData.passwordHash,
        role: userData.role,
        name: userData.name,
      },
      create: userData,
    });
    console.log(`✅ Created/updated user: ${userData.email} (${userData.role})`);
  }

  console.log('\n✨ All test users created successfully!');
  console.log('📧 Email: user@meowtopia.com');
  console.log('🔑 Password: Test1234!');
}

main()
  .catch((e) => {
    console.error('❌ Error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });















