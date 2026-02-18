import { NextRequest, NextResponse } from "next/server";
import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { getDatabase } from "@/lib/mongodb";
import { redisHelpers } from "@/lib/redis";
import { kafkaHelpers } from "@/lib/kafka";

interface ChartDataPoint {
  date: string;
  value: number;
  comparisonValue?: number;
}

// Helper to format dates based on period
function formatDateForPeriod(date: Date, period: "day" | "month" | "year"): string {
  if (period === "day") {
    return date.toISOString().split("T")[0]; // YYYY-MM-DD
  } else if (period === "month") {
    const month = String(date.getMonth() + 1).padStart(2, "0");
    return `${date.getFullYear()}-${month}-01`;
  } else {
    return `${date.getFullYear()}-01-01`;
  }
}

// Helper to group data by period
function groupDataByPeriod(
  data: Array<{ date: Date; value: number }>,
  period: "day" | "month" | "year"
): ChartDataPoint[] {
  const grouped = new Map<string, number>();

  data.forEach((item) => {
    const key = formatDateForPeriod(item.date, period);
    grouped.set(key, (grouped.get(key) || 0) + item.value);
  });

  return Array.from(grouped.entries())
    .map(([date, value]) => ({ date, value }))
    .sort((a, b) => a.date.localeCompare(b.date));
}

export async function GET(request: NextRequest) {
  try {
    const session = await getServerSession(authOptions);
    if (!session) {
      return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
    }

    const searchParams = request.nextUrl.searchParams;
    const start = new Date(searchParams.get("start") || Date.now() - 30 * 24 * 60 * 60 * 1000);
    const end = new Date(searchParams.get("end") || Date.now());
    const period = (searchParams.get("period") || "month") as "day" | "month" | "year";
    const comparisonStart = searchParams.get("comparisonStart")
      ? new Date(searchParams.get("comparisonStart")!)
      : null;
    const comparisonEnd = searchParams.get("comparisonEnd")
      ? new Date(searchParams.get("comparisonEnd")!)
      : null;

    // Try to get from cache first
    const cacheKey = `charts:${start.toISOString()}:${end.toISOString()}:${period}:${comparisonStart?.toISOString() || ""}:${comparisonEnd?.toISOString() || ""}`;
    const cached = await redisHelpers.cacheGet(cacheKey);
    if (cached) {
      // Send analytics event
      kafkaHelpers.sendAnalyticsEvent("dashboard_charts_cached", {
        period,
        cached: true,
      });
      return NextResponse.json(cached);
    }

    // Get data from PostgreSQL
    const [
      orders,
      revenue,
      users,
      products,
      socialMediaStats,
      websiteTraffic,
      campaigns,
      offers,
    ] = await Promise.all([
      // Orders
      prisma.order.findMany({
        where: {
          createdAt: { gte: start, lte: end },
        },
        select: { createdAt: true, total: true },
      }),

      // Revenue (from orders)
      prisma.order.findMany({
        where: {
          createdAt: { gte: start, lte: end },
          paymentStatus: "PAID",
        },
        select: { createdAt: true, total: true },
      }),

      // Users
      prisma.user.findMany({
        where: {
          createdAt: { gte: start, lte: end },
        },
        select: { createdAt: true },
      }),

      // Products
      prisma.product.findMany({
        where: {
          createdAt: { gte: start, lte: end },
        },
        select: { createdAt: true },
      }),

      // Social Media Stats
      prisma.socialMediaStats.findMany({
        where: {
          lastUpdated: { gte: start, lte: end },
        },
      }),

      // Website Traffic
      prisma.websiteTraffic.findMany({
        where: {
          date: { gte: start, lte: end },
        },
      }),

      // Campaigns (Newsletter subscribers as proxy)
      prisma.newsletter.findMany({
        where: {
          subscribedAt: { gte: start, lte: end },
        },
        select: { subscribedAt: true },
      }),

      // Offers (special offers and bundles)
      prisma.product.findMany({
        where: {
          createdAt: { gte: start, lte: end },
          OR: [{ specialOffer: true }, { isBundle: true }],
        },
        select: { createdAt: true },
      }),
    ]);

    // Get comparison data if provided
    let comparisonOrders: typeof orders = [];
    let comparisonRevenue: typeof revenue = [];
    let comparisonUsers: typeof users = [];
    let comparisonProducts: typeof products = [];
    let comparisonTraffic: typeof websiteTraffic = [];

    if (comparisonStart && comparisonEnd) {
      [
        comparisonOrders,
        comparisonRevenue,
        comparisonUsers,
        comparisonProducts,
        comparisonTraffic,
      ] = await Promise.all([
        prisma.order.findMany({
          where: {
            createdAt: { gte: comparisonStart, lte: comparisonEnd },
          },
          select: { createdAt: true, total: true },
        }),
        prisma.order.findMany({
          where: {
            createdAt: { gte: comparisonStart, lte: comparisonEnd },
            paymentStatus: "PAID",
          },
          select: { createdAt: true, total: true },
        }),
        prisma.user.findMany({
          where: {
            createdAt: { gte: comparisonStart, lte: comparisonEnd },
          },
          select: { createdAt: true },
        }),
        prisma.product.findMany({
          where: {
            createdAt: { gte: comparisonStart, lte: comparisonEnd },
          },
          select: { createdAt: true },
        }),
        prisma.websiteTraffic.findMany({
          where: {
            date: { gte: comparisonStart, lte: comparisonEnd },
          },
        }),
      ]);
    }

    // Process orders data
    const ordersData = groupDataByPeriod(
      orders.map((o) => ({ date: o.createdAt, value: 1 })),
      period
    );
    const ordersComparison = comparisonOrders.length > 0
      ? groupDataByPeriod(
          comparisonOrders.map((o) => ({ date: o.createdAt, value: 1 })),
          period
        )
      : [];

    // Process revenue data
    const revenueData = groupDataByPeriod(
      revenue.map((r) => ({ date: r.createdAt, value: Number(r.total) })),
      period
    );
    const revenueComparison = comparisonRevenue.length > 0
      ? groupDataByPeriod(
          comparisonRevenue.map((r) => ({ date: r.createdAt, value: Number(r.total) })),
          period
        )
      : [];

    // Process users data
    const usersData = groupDataByPeriod(
      users.map((u) => ({ date: u.createdAt, value: 1 })),
      period
    );
    const usersComparison = comparisonUsers.length > 0
      ? groupDataByPeriod(
          comparisonUsers.map((u) => ({ date: u.createdAt, value: 1 })),
          period
        )
      : [];

    // Process products data
    const productsData = groupDataByPeriod(
      products.map((p) => ({ date: p.createdAt, value: 1 })),
      period
    );

    // Process social media data (from MongoDB AI analytics if available, otherwise PostgreSQL)
    let socialMediaData: ChartDataPoint[] = [];
    try {
      const db = await getDatabase();
      const analyticsCollection = db.collection("analytics");
      const socialData = await analyticsCollection
        .find({
          type: "social_media",
          date: { $gte: start, $lte: end },
        })
        .sort({ date: 1 })
        .toArray();

      if (socialData.length > 0) {
        // Use MongoDB AI analytics data
        socialMediaData = groupDataByPeriod(
          socialData.map((d: any) => ({
            date: d.date instanceof Date ? d.date : new Date(d.date),
            value: d.followers || d.views || d.engagement || 0,
          })),
          period
        );
      } else {
        // Fallback to PostgreSQL
        const grouped = new Map<string, number>();
        socialMediaStats.forEach((stat) => {
          const key = formatDateForPeriod(stat.lastUpdated, period);
          grouped.set(key, (grouped.get(key) || 0) + stat.followers);
        });
        socialMediaData = Array.from(grouped.entries())
          .map(([date, value]) => ({ date, value }))
          .sort((a, b) => a.date.localeCompare(b.date));
      }
    } catch (error) {
      // MongoDB not available, use PostgreSQL
      const grouped = new Map<string, number>();
      socialMediaStats.forEach((stat) => {
        const key = formatDateForPeriod(stat.lastUpdated, period);
        grouped.set(key, (grouped.get(key) || 0) + stat.followers);
      });
      socialMediaData = Array.from(grouped.entries())
        .map(([date, value]) => ({ date, value }))
        .sort((a, b) => a.date.localeCompare(b.date));
    }

    // Process traffic data (aggregate from all sources)
    const trafficData = groupDataByPeriod(
      websiteTraffic.map((t) => ({ date: t.date, value: t.pageViews })),
      period
    );
    const trafficComparison = comparisonTraffic.length > 0
      ? groupDataByPeriod(
          comparisonTraffic.map((t) => ({ date: t.date, value: t.pageViews })),
          period
        )
      : [];

    // Process campaigns data
    const campaignsData = groupDataByPeriod(
      campaigns.map((c) => ({ date: c.subscribedAt, value: 1 })),
      period
    );

    // Process offers data
    const offersData = groupDataByPeriod(
      offers.map((o) => ({ date: o.createdAt, value: 1 })),
      period
    );

    // Merge comparison data
    const mergeComparison = (
      main: ChartDataPoint[],
      comparison: ChartDataPoint[]
    ): ChartDataPoint[] => {
      if (comparison.length === 0) return main;
      const comparisonMap = new Map(comparison.map((c) => [c.date, c.value]));
      return main.map((m) => ({
        ...m,
        comparisonValue: comparisonMap.get(m.date),
      }));
    };

    const result = {
      orders: mergeComparison(ordersData, ordersComparison),
      revenue: mergeComparison(revenueData, revenueComparison),
      users: mergeComparison(usersData, usersComparison),
      products: productsData,
      socialMedia: socialMediaData,
      traffic: mergeComparison(trafficData, trafficComparison),
      campaigns: campaignsData,
      offers: offersData,
    };

    // Cache the result for 5 minutes
    await redisHelpers.cacheSet(cacheKey, result, 300);

    // Send analytics event to Kafka
    kafkaHelpers.sendAnalyticsEvent("dashboard_charts_generated", {
      period,
      dataPoints: {
        orders: result.orders.length,
        revenue: result.revenue.length,
        users: result.users.length,
        products: result.products.length,
        socialMedia: result.socialMedia.length,
        traffic: result.traffic.length,
        campaigns: result.campaigns.length,
        offers: result.offers.length,
      },
    });

    return NextResponse.json(result);
  } catch (error) {
    console.error("Error fetching chart data:", error);
    return NextResponse.json(
      { error: "Failed to fetch chart data" },
      { status: 500 }
    );
  }
}

