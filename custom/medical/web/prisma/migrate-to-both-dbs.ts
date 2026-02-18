/**
 * Migration script to sync Prisma schema to both PostgreSQL and MongoDB
 * This script ensures data consistency across both databases
 */

// @ts-ignore - PrismaClient may not be available during build
import { PrismaClient } from '@prisma/client';
import { getDatabase } from '@/lib/mongodb';

// @ts-ignore
const prisma = typeof PrismaClient !== 'undefined' ? new PrismaClient() : null;

/**
 * Sync patient profile data to MongoDB for faster queries
 */
export async function syncPatientProfileToMongoDB(userId: string, profileData: any) {
  try {
    const db = await getDatabase();
    const collection = db.collection('patient_profiles');
    
    await collection.updateOne(
      { userId },
      {
        $set: {
          ...profileData,
          updatedAt: new Date(),
        },
      },
      { upsert: true }
    );
  } catch (error) {
    console.error('Failed to sync to MongoDB:', error);
    // Don't throw - MongoDB sync is optional
  }
}

/**
 * Sync User data to MongoDB for faster queries
 */
export async function syncUserToMongoDB(userId: string, userData: any) {
  try {
    const db = await getDatabase();
    const collection = db.collection('users');
    
    await collection.updateOne(
      { id: userId },
      {
        $set: {
          ...userData,
          updatedAt: new Date(),
        },
      },
      { upsert: true }
    );
  } catch (error) {
    console.error('Failed to sync user to MongoDB:', error);
    // Don't throw - MongoDB sync is optional
  }
}

/**
 * Initialize Prisma and run migrations
 */
export async function initializePrisma() {
  try {
    // Prisma will handle PostgreSQL migrations automatically
    if (!prisma) {
      throw new Error('PrismaClient is not available');
    }
    await prisma.$connect();
    console.log('✅ Prisma connected to PostgreSQL');
  } catch (error) {
    console.error('❌ Failed to connect Prisma:', error);
    throw error;
  }
}

/**
 * Initialize MongoDB collections and indexes
 */
export async function initializeMongoDB() {
  try {
    const db = await getDatabase();
    
    // Create indexes for users collection
    const usersCollection = db.collection('users');
    await usersCollection.createIndex({ id: 1 }, { unique: true });
    await usersCollection.createIndex({ email: 1 }, { unique: true });
    
    // Create indexes for patient_profiles collection
    const patientProfilesCollection = db.collection('patient_profiles');
    await patientProfilesCollection.createIndex({ userId: 1 }, { unique: true });
    
    // Create indexes for ai_workflows collection (if exists)
    const aiWorkflowsCollection = db.collection('ai_workflows');
    await aiWorkflowsCollection.createIndex({ createdAt: -1 });
    
    console.log('✅ MongoDB collections and indexes initialized');
  } catch (error) {
    console.error('❌ Failed to initialize MongoDB:', error);
    // Don't throw - MongoDB is optional
  }
}

export { prisma };




