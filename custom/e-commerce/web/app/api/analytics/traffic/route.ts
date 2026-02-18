import { NextRequest, NextResponse } from "next/server";
import { getTrafficStatsFromDB, getGoogleAnalyticsStats } from "@/lib/api/google-analytics";
import { prisma } from "@/lib/prisma";

/**
 * GET /api/analytics/traffic
 * Pobiera statystyki ruchu na stronie
 */
export async function GET(request: NextRequest) {
  try {
    const { searchParams } = new URL(request.url);
    const days = parseInt(searchParams.get("days") || "30");

    // Próbuj pobrać z Google Analytics jeśli skonfigurowane
    const propertyId = process.env.GOOGLE_ANALYTICS_PROPERTY_ID;
    const credentials = process.env.GOOGLE_ANALYTICS_CREDENTIALS
      ? JSON.parse(process.env.GOOGLE_ANALYTICS_CREDENTIALS)
      : null;

    let stats;

    if (propertyId && credentials) {
      const endDate = new Date();
      const startDate = new Date();
      startDate.setDate(startDate.getDate() - days);

      const gaStats = await getGoogleAnalyticsStats(
        propertyId,
        credentials,
        startDate,
        endDate
      );

      if (gaStats) {
        // Zapisz do bazy danych
        const today = new Date();
        today.setHours(0, 0, 0, 0);

        // Sprawdź czy istnieje rekord na dzisiaj
        const existing = await prisma.websiteTraffic.findFirst({
          where: {
            date: {
              gte: today,
              lt: new Date(today.getTime() + 24 * 60 * 60 * 1000),
            },
            source: "google-analytics",
          },
        });

        if (existing) {
          await prisma.websiteTraffic.update({
            where: { id: existing.id },
            data: {
              visitors: gaStats.visitors,
              pageViews: gaStats.pageViews,
              sessions: gaStats.sessions,
              bounceRate: gaStats.bounceRate,
              avgSessionDuration: gaStats.avgSessionDuration,
            },
          });
        } else {
          await prisma.websiteTraffic.create({
            data: {
              date: today,
              visitors: gaStats.visitors,
              pageViews: gaStats.pageViews,
              sessions: gaStats.sessions,
              bounceRate: gaStats.bounceRate,
              avgSessionDuration: gaStats.avgSessionDuration,
              source: "google-analytics",
            },
          });
        }

        stats = gaStats;
      }
    }

    // Jeśli nie ma danych z GA, pobierz z bazy danych
    if (!stats) {
      stats = await getTrafficStatsFromDB(days);
    }

    return NextResponse.json({ stats }, { status: 200 });
  } catch (error) {
    console.error("Error fetching traffic stats:", error);
    return NextResponse.json(
      { error: "Failed to fetch traffic stats" },
      { status: 500 }
    );
  }
}

