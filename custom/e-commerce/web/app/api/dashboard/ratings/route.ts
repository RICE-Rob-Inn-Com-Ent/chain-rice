import { NextRequest, NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { getDatabase } from "@/lib/mongodb";
import { redisHelpers } from "@/lib/redis";
import { kafkaHelpers } from "@/lib/kafka";

// Calculate rating percentage (5.0 = 100%)
function calculateRatingPercentage(rating: number): number {
  return (rating / 5.0) * 100;
}

// Aggregate ratings from multiple sources
async function getAggregatedRatings() {
  const sources: Array<{ name: string; rating: number; weight: number }> = [];

  // 1. Internal reviews from PostgreSQL
  const internalReviews = await prisma.productReview.aggregate({
    _avg: { rating: true },
    where: { approved: true },
  });
  const internalRating = internalReviews._avg.rating || 0;
  if (internalRating > 0) {
    sources.push({
      name: "Wewnętrzne opinie",
      rating: internalRating,
      weight: 0.3, // 30% weight
    });
  }

  // 2. Google Reviews (from MongoDB AI analytics)
  try {
    const db = await getDatabase();
    const analyticsCollection = db.collection("analytics");
    const googleData = await analyticsCollection.findOne({
      type: "google_reviews",
    });

    if (googleData && googleData.rating) {
      sources.push({
        name: "Google",
        rating: googleData.rating,
        weight: 0.4, // 40% weight (highest)
      });
    }
  } catch (error) {
    console.warn("MongoDB not available for Google reviews:", error);
  }

  // 3. Meta/Facebook Reviews (from MongoDB)
  try {
    const db = await getDatabase();
    const analyticsCollection = db.collection("analytics");
    const metaData = await analyticsCollection.findOne({
      type: "meta_reviews",
    });

    if (metaData && metaData.rating) {
      sources.push({
        name: "Meta/Facebook",
        rating: metaData.rating,
        weight: 0.2, // 20% weight
      });
    }
  } catch (error) {
    console.warn("MongoDB not available for Meta reviews:", error);
  }

  // 4. Other review sites (from MongoDB)
  try {
    const db = await getDatabase();
    const analyticsCollection = db.collection("analytics");
    const otherReviews = await analyticsCollection
      .find({
        type: "external_reviews",
      })
      .toArray();

    if (otherReviews.length > 0) {
      const avgRating =
        otherReviews.reduce((sum: number, r: any) => sum + (r.rating || 0), 0) /
        otherReviews.length;
      if (avgRating > 0) {
        sources.push({
          name: "Inne strony",
          rating: avgRating,
          weight: 0.1, // 10% weight
        });
      }
    }
  } catch (error) {
    console.warn("MongoDB not available for external reviews:", error);
  }

  // Calculate weighted average
  if (sources.length === 0) {
    return {
      overallRating: 0,
      overallPercentage: 0,
      sources: [],
    };
  }

  const totalWeight = sources.reduce((sum, s) => sum + s.weight, 0);
  const weightedSum = sources.reduce(
    (sum, s) => sum + s.rating * s.weight,
    0
  );
  const overallRating = totalWeight > 0 ? weightedSum / totalWeight : 0;

  return {
    overallRating: Number(overallRating.toFixed(2)),
    overallPercentage: Number(calculateRatingPercentage(overallRating).toFixed(1)),
    sources: sources.map((s) => ({
      ...s,
      percentage: calculateRatingPercentage(s.rating),
    })),
  };
}

export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Try to get from cache first (cache for 10 minutes)
    const cacheKey = "ratings:aggregated";
    const cached = await redisHelpers.cacheGet(cacheKey);
    if (cached) {
      return NextResponse.json(cached);
    }

    const ratings = await getAggregatedRatings();

    // Cache the result
    await redisHelpers.cacheSet(cacheKey, ratings, 600);

    // Send analytics event to Kafka
    kafkaHelpers.sendAnalyticsEvent("ratings_aggregated", {
      overallRating: ratings.overallRating,
      overallPercentage: ratings.overallPercentage,
      sourcesCount: ratings.sources.length,
    });

    return NextResponse.json(ratings);
  } catch (error) {
    console.error("Error fetching ratings:", error);
    return NextResponse.json(
      { error: "Failed to fetch ratings" },
      { status: 500 }
    );
  }
}

