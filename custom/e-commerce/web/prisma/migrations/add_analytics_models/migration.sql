-- CreateTable
CREATE TABLE IF NOT EXISTS "SocialMediaStats" (
    "id" TEXT NOT NULL,
    "platform" TEXT NOT NULL,
    "followers" INTEGER NOT NULL DEFAULT 0,
    "likes" INTEGER NOT NULL DEFAULT 0,
    "comments" INTEGER NOT NULL DEFAULT 0,
    "shares" INTEGER NOT NULL DEFAULT 0,
    "engagementRate" DECIMAL(5,2),
    "lastUpdated" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SocialMediaStats_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE IF NOT EXISTS "WebsiteTraffic" (
    "id" TEXT NOT NULL,
    "date" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "visitors" INTEGER NOT NULL DEFAULT 0,
    "pageViews" INTEGER NOT NULL DEFAULT 0,
    "sessions" INTEGER NOT NULL DEFAULT 0,
    "bounceRate" DECIMAL(5,2),
    "avgSessionDuration" INTEGER,
    "source" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "WebsiteTraffic_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX IF NOT EXISTS "SocialMediaStats_platform_key" ON "SocialMediaStats"("platform");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "SocialMediaStats_platform_lastUpdated_idx" ON "SocialMediaStats"("platform", "lastUpdated");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "WebsiteTraffic_date_idx" ON "WebsiteTraffic"("date");

-- CreateIndex
CREATE INDEX IF NOT EXISTS "WebsiteTraffic_source_date_idx" ON "WebsiteTraffic"("source", "date");



