/**
 * Google Analytics API integration
 * Pobiera statystyki ruchu na stronie
 */

interface GoogleAnalyticsResponse {
  rows?: Array<{
    dimensionValues: Array<{ value: string }>;
    metricValues: Array<{ value: string }>;
  }>;
  totals?: Array<{
    metricValues: Array<{ value: string }>;
  }>;
}

interface TrafficStats {
  visitors: number;
  pageViews: number;
  sessions: number;
  bounceRate: number | null;
  avgSessionDuration: number | null;
}

/**
 * Pobiera statystyki z Google Analytics Data API
 */
export async function getGoogleAnalyticsStats(
  propertyId: string,
  credentials: any,
  startDate: Date,
  endDate: Date
): Promise<TrafficStats | null> {
  try {
    // Sprawdź czy pakiet jest dostępny
    let BetaAnalyticsDataClient;
    try {
      const analyticsModule = await import("@google-analytics/data");
      BetaAnalyticsDataClient = analyticsModule.BetaAnalyticsDataClient;
    } catch (importError) {
      console.warn(
        "@google-analytics/data package not available, using database stats instead"
      );
      return null;
    }

    if (!BetaAnalyticsDataClient) {
      return null;
    }

    const analyticsDataClient = new BetaAnalyticsDataClient({
      credentials: credentials,
    });

    const [response] = await analyticsDataClient.runReport({
      property: `properties/${propertyId}`,
      dateRanges: [
        {
          startDate: startDate.toISOString().split("T")[0],
          endDate: endDate.toISOString().split("T")[0],
        },
      ],
      dimensions: [{ name: "date" }],
      metrics: [
        { name: "activeUsers" },
        { name: "screenPageViews" },
        { name: "sessions" },
        { name: "bounceRate" },
        { name: "averageSessionDuration" },
      ],
    });

    if (!response.rows || response.rows.length === 0) {
      return null;
    }

    // Agreguj dane z wszystkich dni
    let totalVisitors = 0;
    let totalPageViews = 0;
    let totalSessions = 0;
    let totalBounceRate = 0;
    let totalAvgDuration = 0;
    let count = 0;

    for (const row of response.rows) {
      const metrics = row.metricValues || [];
      totalVisitors += parseInt(metrics[0]?.value || "0", 10);
      totalPageViews += parseInt(metrics[1]?.value || "0", 10);
      totalSessions += parseInt(metrics[2]?.value || "0", 10);
      totalBounceRate += parseFloat(metrics[3]?.value || "0");
      totalAvgDuration += parseFloat(metrics[4]?.value || "0");
      count++;
    }

    return {
      visitors: totalVisitors,
      pageViews: totalPageViews,
      sessions: totalSessions,
      bounceRate: count > 0 ? totalBounceRate / count : null,
      avgSessionDuration: count > 0 ? Math.round(totalAvgDuration / count) : null,
    };
  } catch (error) {
    console.error("Error fetching Google Analytics stats:", error);
    return null;
  }
}

/**
 * Alternatywna metoda - własny tracking
 * Można użyć do zapisywania danych z własnego systemu trackingowego
 */
export async function recordPageView(
  sessionId: string,
  path: string,
  source?: string
) {
  const { prisma } = await import("@/lib/prisma");

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  // Znajdź lub utwórz rekord dla dzisiaj
  const existing = await prisma.websiteTraffic.findFirst({
    where: {
      date: {
        gte: today,
        lt: new Date(today.getTime() + 24 * 60 * 60 * 1000),
      },
      source: source || "direct",
    },
  });

  if (existing) {
    await prisma.websiteTraffic.update({
      where: { id: existing.id },
      data: {
        pageViews: { increment: 1 },
        visitors: existing.visitors, // Visitors powinny być liczone unikalnie
      },
    });
  } else {
    await prisma.websiteTraffic.create({
      data: {
        date: today,
        visitors: 1,
        pageViews: 1,
        sessions: 1,
        source: source || "direct",
      },
    });
  }
}

/**
 * Pobiera statystyki ruchu z bazy danych
 */
export async function getTrafficStatsFromDB(
  days: number = 30
): Promise<TrafficStats> {
  const { prisma } = await import("@/lib/prisma");

  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);

  const stats = await prisma.websiteTraffic.aggregate({
    where: {
      date: {
        gte: startDate,
      },
    },
    _sum: {
      visitors: true,
      pageViews: true,
      sessions: true,
    },
    _avg: {
      bounceRate: true,
      avgSessionDuration: true,
    },
  });

  return {
    visitors: stats._sum.visitors || 0,
    pageViews: stats._sum.pageViews || 0,
    sessions: stats._sum.sessions || 0,
    bounceRate: stats._avg.bounceRate ? Number(stats._avg.bounceRate) : null,
    avgSessionDuration: stats._avg.avgSessionDuration
      ? Number(stats._avg.avgSessionDuration)
      : null,
  };
}

