/**
 * Facebook Graph API integration
 * Pobiera statystyki z Facebook i Instagram
 */

interface FacebookPageStats {
  followers_count?: number;
  fan_count?: number;
  likes?: number;
}

interface InstagramAccountStats {
  followers_count?: number;
  media_count?: number;
}

interface FacebookPostStats {
  likes?: { summary: { total_count: number } };
  comments?: { summary: { total_count: number } };
  shares?: { count: number };
}

export async function getFacebookPageStats(
  pageId: string,
  accessToken: string
): Promise<FacebookPageStats | null> {
  try {
    const response = await fetch(
      `https://graph.facebook.com/v18.0/${pageId}?fields=followers_count,fan_count,likes&access_token=${accessToken}`
    );

    if (!response.ok) {
      console.error("Facebook API error:", await response.text());
      return null;
    }

    return await response.json();
  } catch (error) {
    console.error("Error fetching Facebook stats:", error);
    return null;
  }
}

export async function getInstagramAccountStats(
  instagramBusinessAccountId: string,
  accessToken: string
): Promise<InstagramAccountStats | null> {
  try {
    const response = await fetch(
      `https://graph.facebook.com/v18.0/${instagramBusinessAccountId}?fields=followers_count,media_count&access_token=${accessToken}`
    );

    if (!response.ok) {
      console.error("Instagram API error:", await response.text());
      return null;
    }

    return await response.json();
  } catch (error) {
    console.error("Error fetching Instagram stats:", error);
    return null;
  }
}

export async function getRecentPostsEngagement(
  pageId: string,
  accessToken: string,
  limit: number = 10
): Promise<{ likes: number; comments: number; shares: number }> {
  try {
    const response = await fetch(
      `https://graph.facebook.com/v18.0/${pageId}/posts?fields=likes.summary(true),comments.summary(true),shares&limit=${limit}&access_token=${accessToken}`
    );

    if (!response.ok) {
      console.error("Facebook posts API error:", await response.text());
      return { likes: 0, comments: 0, shares: 0 };
    }

    const data = await response.json();
    const posts = data.data || [];

    const totals = posts.reduce(
      (acc: { likes: number; comments: number; shares: number }, post: FacebookPostStats) => {
        acc.likes += post.likes?.summary?.total_count || 0;
        acc.comments += post.comments?.summary?.total_count || 0;
        acc.shares += post.shares?.count || 0;
        return acc;
      },
      { likes: 0, comments: 0, shares: 0 }
    );

    return totals;
  } catch (error) {
    console.error("Error fetching posts engagement:", error);
    return { likes: 0, comments: 0, shares: 0 };
  }
}

export async function fetchAndUpdateSocialMediaStats() {
  const accessToken = process.env.FACEBOOK_ACCESS_TOKEN;
  const facebookPageId = process.env.FACEBOOK_PAGE_ID;
  const instagramAccountId = process.env.INSTAGRAM_BUSINESS_ACCOUNT_ID;

  if (!accessToken) {
    console.warn("FACEBOOK_ACCESS_TOKEN not configured");
    return;
  }

  const { prisma } = await import("@/lib/prisma");

  // Facebook stats
  if (facebookPageId) {
    const fbStats = await getFacebookPageStats(facebookPageId, accessToken);
    const postsEngagement = await getRecentPostsEngagement(facebookPageId, accessToken);

    if (fbStats) {
      const followers = fbStats.followers_count || fbStats.fan_count || 0;
      const engagementRate =
        followers > 0
          ? ((postsEngagement.likes + postsEngagement.comments + postsEngagement.shares) /
              followers) *
            100
          : null;

      await prisma.socialMediaStats.upsert({
        where: { platform: "facebook" },
        update: {
          followers: followers,
          likes: postsEngagement.likes,
          comments: postsEngagement.comments,
          shares: postsEngagement.shares,
          engagementRate: engagementRate ? Number(engagementRate.toFixed(2)) : null,
        },
        create: {
          platform: "facebook",
          followers: followers,
          likes: postsEngagement.likes,
          comments: postsEngagement.comments,
          shares: postsEngagement.shares,
          engagementRate: engagementRate ? Number(engagementRate.toFixed(2)) : null,
        },
      });
    }
  }

  // Instagram stats
  if (instagramAccountId) {
    const igStats = await getInstagramAccountStats(instagramAccountId, accessToken);

    if (igStats) {
      await prisma.socialMediaStats.upsert({
        where: { platform: "instagram" },
        update: {
          followers: igStats.followers_count || 0,
          likes: 0, // Instagram API v18 wymaga osobnych zapytań dla postów
          comments: 0,
          shares: 0,
        },
        create: {
          platform: "instagram",
          followers: igStats.followers_count || 0,
          likes: 0,
          comments: 0,
          shares: 0,
        },
      });
    }
  }
}





































