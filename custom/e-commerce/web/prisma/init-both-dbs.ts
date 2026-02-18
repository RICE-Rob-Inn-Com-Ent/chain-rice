/**
 * Initialize both PostgreSQL (via Prisma) and MongoDB databases
 * Run this script to set up tables and collections in both databases
 */

import { initializePrisma, initializeMongoDB } from './migrate-to-both-dbs';

async function main() {
  console.log('🚀 Initializing databases...\n');

  try {
    // Initialize PostgreSQL via Prisma
    console.log('📊 Initializing PostgreSQL...');
    await initializePrisma();
    console.log('✅ PostgreSQL initialized\n');

    // Initialize MongoDB
    console.log('🍃 Initializing MongoDB...');
    await initializeMongoDB();
    console.log('✅ MongoDB initialized\n');

    console.log('✨ All databases initialized successfully!');
  } catch (error) {
    console.error('❌ Failed to initialize databases:', error);
    process.exit(1);
  } finally {
    process.exit(0);
  }
}

main();

















