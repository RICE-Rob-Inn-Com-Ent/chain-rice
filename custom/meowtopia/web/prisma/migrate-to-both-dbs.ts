/**
 * Migration script to sync Prisma schema to both PostgreSQL and MongoDB
 * This script ensures data consistency across both databases
 */

// Prisma types - will be available after running: yarn prisma generate
// @ts-ignore - Prisma types not generated yet
import { PrismaClient } from '@prisma/client';
import { getDatabase } from '@/lib/mongodb';

const prisma = new PrismaClient();

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
 * Sync Product data to MongoDB for faster queries
 */
export async function syncProductToMongoDB(productId: string, productData: any) {
  try {
    const db = await getDatabase();
    const collection = db.collection('products');
    
    await collection.updateOne(
      { id: productId },
      {
        $set: {
          ...productData,
          updatedAt: new Date(),
        },
      },
      { upsert: true }
    );
  } catch (error) {
    console.error('Failed to sync product to MongoDB:', error);
    // Don't throw - MongoDB sync is optional
  }
}

/**
 * Sync Order data to MongoDB for faster queries
 */
export async function syncOrderToMongoDB(orderId: string, orderData: any) {
  try {
    const db = await getDatabase();
    const collection = db.collection('orders');
    
    await collection.updateOne(
      { id: orderId },
      {
        $set: {
          ...orderData,
          updatedAt: new Date(),
        },
      },
      { upsert: true }
    );
  } catch (error) {
    console.error('Failed to sync order to MongoDB:', error);
    // Don't throw - MongoDB sync is optional
  }
}

/**
 * Sync Cart data to MongoDB for faster queries
 */
export async function syncCartToMongoDB(cartId: string, cartData: any) {
  try {
    const db = await getDatabase();
    const collection = db.collection('carts');
    
    await collection.updateOne(
      { id: cartId },
      {
        $set: {
          ...cartData,
          updatedAt: new Date(),
        },
      },
      { upsert: true }
    );
  } catch (error) {
    console.error('Failed to sync cart to MongoDB:', error);
    // Don't throw - MongoDB sync is optional
  }
}

/**
 * Initialize Prisma and run migrations
 */
export async function initializePrisma() {
  try {
    // Prisma will handle PostgreSQL migrations automatically
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
    await usersCollection.createIndex({ role: 1 });
    
    // Create indexes for products collection
    const productsCollection = db.collection('products');
    await productsCollection.createIndex({ id: 1 }, { unique: true });
    await productsCollection.createIndex({ category: 1, active: 1 });
    await productsCollection.createIndex({ featured: 1, active: 1 });
    
    // Create indexes for orders collection
    const ordersCollection = db.collection('orders');
    await ordersCollection.createIndex({ id: 1 }, { unique: true });
    await ordersCollection.createIndex({ orderNumber: 1 }, { unique: true });
    await ordersCollection.createIndex({ userId: 1 });
    await ordersCollection.createIndex({ status: 1 });
    
    // Create indexes for carts collection
    const cartsCollection = db.collection('carts');
    await cartsCollection.createIndex({ id: 1 }, { unique: true });
    await cartsCollection.createIndex({ userId: 1 }, { unique: true, sparse: true });
    await cartsCollection.createIndex({ sessionId: 1 }, { unique: true, sparse: true });
    
    console.log('✅ MongoDB collections and indexes initialized');
  } catch (error) {
    console.error('❌ Failed to initialize MongoDB:', error);
    // Don't throw - MongoDB is optional
  }
}

export { prisma };















