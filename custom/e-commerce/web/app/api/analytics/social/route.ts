import { NextRequest, NextResponse } from "next/server";
import { fetchAndUpdateSocialMediaStats } from "@/lib/api/facebook";
import { prisma } from "@/lib/prisma";

/**
 * GET /api/analytics/social
 * Pobiera statystyki social media z bazy danych
 */
export async function GET(request: NextRequest) {
  try {
    const stats = await prisma.socialMediaStats.findMany({
      orderBy: { lastUpdated: "desc" },
    });

    return NextResponse.json({ stats }, { status: 200 });
  } catch (error) {
    console.error("Error fetching social media stats:", error);
    return NextResponse.json(
      { error: "Failed to fetch social media stats" },
      { status: 500 }
    );
  }
}

/**
 * POST /api/analytics/social
 * Aktualizuje statystyki social media z API
 */
export async function POST(request: NextRequest) {
  try {
    await fetchAndUpdateSocialMediaStats();

    const stats = await prisma.socialMediaStats.findMany({
      orderBy: { lastUpdated: "desc" },
    });

    return NextResponse.json(
      { message: "Social media stats updated", stats },
      { status: 200 }
    );
  } catch (error) {
    console.error("Error updating social media stats:", error);
    return NextResponse.json(
      { error: "Failed to update social media stats" },
      { status: 500 }
    );
  }
}



