import { NextRequest, NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { getDatabase } from "@/lib/mongodb";
import { redisHelpers } from "@/lib/redis";
import { kafkaHelpers } from "@/lib/kafka";

// Aggregate views from all social media platforms
async function getAggregatedViews() {
  let totalViews = 0;
  const sources: Array<{ platform: string; views: number }> = [];

  // 1. Website Traffic from PostgreSQL
  const websiteTraffic = await prisma.websiteTraffic.aggregate({
    _sum: { pageViews: true },
    where: {
      date: {
        gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // Last 30 days
      },
    },
  });
  const websiteViews = Number(websiteTraffic._sum.pageViews || 0);
  if (websiteViews > 0) {
    sources.push({
      platform: "Strona internetowa",
      views: websiteViews,
    });
    totalViews += websiteViews;
  }

  // 2. Social Media from MongoDB (AI analytics)
  try {
    const db = await getDatabase();
    const analyticsCollection = db.collection("analytics");
    const socialData = await analyticsCollection
      .find({
        type: "social_media_views",
        date: {
          $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
        },
      })
      .toArray();

    const platformViews = new Map<string, number>();

    socialData.forEach((item: any) => {
      const platform = item.platform || "unknown";
      const views = item.views || item.impressions || 0;
      platformViews.set(
        platform,
        (platformViews.get(platform) || 0) + views
      );
    });

    platformViews.forEach((views, platform) => {
      if (views > 0) {
        const platformName =
          platform === "facebook"
            ? "Facebook"
            : platform === "instagram"
            ? "Instagram"
            : platform === "twitter"
            ? "Twitter/X"
            : platform === "tiktok"
            ? "TikTok"
            : platform === "youtube"
            ? "YouTube"
            : platform.charAt(0).toUpperCase() + platform.slice(1);

        sources.push({
          platform: platformName,
          views: views,
        });
        totalViews += views;
      }
    });
  } catch (error) {
    console.warn("MongoDB not available for social media views:", error);
    // Fallback to PostgreSQL SocialMediaStats
    const socialStats = await prisma.socialMediaStats.findMany();
    socialStats.forEach((stat) => {
      const views = stat.likes + stat.comments + stat.shares; // Engagement as proxy for views
      if (views > 0) {
        const platformName =
          stat.platform === "facebook"
            ? "Facebook"
            : stat.platform === "instagram"
            ? "Instagram"
            : stat.platform === "twitter"
            ? "Twitter/X"
            : stat.platform.charAt(0).toUpperCase() + stat.platform.slice(1);

        sources.push({
          platform: platformName,
          views: views,
        });
        totalViews += views;
      }
    });
  }

  return {
    totalViews,
    sources: sources.sort((a, b) => b.views - a.views),
  };
}

export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    // Try to get from cache first (cache for 5 minutes)
    const cacheKey = "views:aggregated:30days";
    const cached = await redisHelpers.cacheGet(cacheKey);
    if (cached) {
      return NextResponse.json(cached);
    }

    const views = await getAggregatedViews();

    // Cache the result
    await redisHelpers.cacheSet(cacheKey, views, 300);

    // Send analytics event to Kafka
    kafkaHelpers.sendAnalyticsEvent("views_aggregated", {
      totalViews: views.totalViews,
      sourcesCount: views.sources.length,
      sources: views.sources.map((s) => s.platform),
    });

    return NextResponse.json(views);
  } catch (error) {
    console.error("Error fetching views:", error);
    return NextResponse.json(
      { error: "Failed to fetch views" },
      { status: 500 }
    );
  }
}

