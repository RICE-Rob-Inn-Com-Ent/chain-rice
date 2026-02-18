/**
 * MongoDB Analytics Helper
 * 
 * This module provides helper functions for storing and retrieving
 * AI-powered analytics data in MongoDB.
 * 
 * Expected MongoDB collections structure:
 * 
 * analytics:
 *   - type: "social_media" | "google_reviews" | "meta_reviews" | "external_reviews" | "social_media_views"
 *   - date: Date
 *   - platform?: string (for social_media: "facebook" | "instagram" | "twitter" | "tiktok" | "youtube")
 *   - followers?: number
 *   - views?: number
 *   - impressions?: number
 *   - engagement?: number
 *   - rating?: number (for reviews)
 *   - source?: string (for external reviews)
 */

import { getDatabase } from "./mongodb";

export interface SocialMediaAnalytics {
  type: "social_media";
  date: Date;
  platform: "facebook" | "instagram" | "twitter" | "tiktok" | "youtube";
  followers: number;
  views?: number;
  impressions?: number;
  engagement?: number;
}

export interface ReviewAnalytics {
  type: "google_reviews" | "meta_reviews" | "external_reviews";
  date: Date;
  rating: number;
  source?: string;
  count?: number;
}

export interface SocialMediaViews {
  type: "social_media_views";
  date: Date;
  platform: string;
  views: number;
  impressions?: number;
}

/**
 * Store social media analytics data
 */
export async function storeSocialMediaAnalytics(data: SocialMediaAnalytics) {
  try {
    const db = await getDatabase();
    const collection = db.collection("analytics");
    await collection.insertOne(data);
  } catch (error) {
    console.error("Failed to store social media analytics:", error);
    // Don't throw - MongoDB is optional
  }
}

/**
 * Store review analytics data
 */
export async function storeReviewAnalytics(data: ReviewAnalytics) {
  try {
    const db = await getDatabase();
    const collection = db.collection("analytics");
    await collection.insertOne(data);
  } catch (error) {
    console.error("Failed to store review analytics:", error);
    // Don't throw - MongoDB is optional
  }
}

/**
 * Store social media views data
 */
export async function storeSocialMediaViews(data: SocialMediaViews) {
  try {
    const db = await getDatabase();
    const collection = db.collection("analytics");
    await collection.insertOne(data);
  } catch (error) {
    console.error("Failed to store social media views:", error);
    // Don't throw - MongoDB is optional
  }
}

/**
 * Get latest analytics data
 */
export async function getLatestAnalytics(type: string) {
  try {
    const db = await getDatabase();
    const collection = db.collection("analytics");
    return await collection
      .findOne(
        { type },
        { sort: { date: -1 } }
      );
  } catch (error) {
    console.error("Failed to get latest analytics:", error);
    return null;
  }
}





































