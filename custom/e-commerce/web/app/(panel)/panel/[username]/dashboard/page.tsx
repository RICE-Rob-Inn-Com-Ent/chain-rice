import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import DashboardContent from "@/components/panel/DashboardContent";

async function getDashboardStats() {
  try {
    const [
      totalProducts,
      totalUsers,
      totalOrders,
      totalRevenue,
      totalDonations,
      avgRating,
      emailSubscribers,
      trafficStats,
      usersWithAccounts,
      newsletterSubscribers,
    ] = await Promise.all([
      prisma.product.count({ where: { active: true } }),
      prisma.user.count(),
      prisma.order.count(),
      prisma.order.aggregate({
        _sum: { total: true },
        where: { paymentStatus: "PAID" },
      }),
      prisma.donationRecord.aggregate({
        _sum: { amount: true },
        where: { status: "transferred" },
      }),
      prisma.productReview.aggregate({
        _avg: { rating: true },
        where: { approved: true },
      }),
      prisma.newsletter.count({
        where: { active: true },
      }),
      prisma.websiteTraffic.aggregate({
        where: {
          date: {
            gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
          },
        },
        _sum: {
          visitors: true,
          pageViews: true,
          sessions: true,
        },
      }).catch(() => ({ _sum: { visitors: 0, pageViews: 0, sessions: 0 } })),
      // Pobierz użytkowników z ich kontami społecznościowymi
      prisma.user.findMany({
        select: {
          id: true,
          accounts: {
            select: {
              provider: true,
              type: true,
            },
          },
        },
      }),
      // Pobierz subskrybentów newslettera
      prisma.newsletter.findMany({
        where: { active: true },
        select: {
          email: true,
        },
      }),
    ]);

    // Oblicz statystyki kont społecznościowych
    const socialAccountsStats = {
      youtube: 0,
      facebook: 0,
      instagram: 0,
      meta: 0,
      google: 0,
      twitter: 0,
      other: 0,
    };

    usersWithAccounts.forEach((user) => {
      const userProviders = new Set<string>();
      user.accounts.forEach((account) => {
        const provider = account.provider.toLowerCase();
        userProviders.add(provider);
      });
      
      // Zlicz unikalne konta dla każdego użytkownika
      userProviders.forEach((provider) => {
        if (provider === "youtube") {
          socialAccountsStats.youtube++;
        } else if (provider === "google") {
          socialAccountsStats.google++;
        } else if (provider === "facebook" || provider === "meta") {
          // Facebook i Meta to to samo - zliczamy jako Meta
          socialAccountsStats.meta++;
        } else if (provider === "instagram") {
          socialAccountsStats.instagram++;
        } else if (provider === "twitter" || provider === "x") {
          socialAccountsStats.twitter++;
        } else {
          socialAccountsStats.other++;
        }
      });
    });

    // Oblicz ile użytkowników ma subskrypcję (email w newsletterze)
    const subscribedUserEmails = new Set(newsletterSubscribers.map((n) => n.email));
    const usersWithSubscriptions = await prisma.user.findMany({
      where: {
        email: {
          in: Array.from(subscribedUserEmails),
        },
      },
      select: {
        id: true,
      },
    });
    const totalSubscribedUsers = usersWithSubscriptions.length;

    const conversionRate =
      totalUsers > 0
        ? ((totalOrders / totalUsers) * 100).toFixed(1) + "%"
        : "0%";

    // Count active offers (special offers and bundles)
    const totalOffers = await prisma.product.count({
      where: {
        OR: [
          { specialOffer: true },
          { isBundle: true },
        ],
        active: true,
      },
    });

    return {
      totalProducts,
      totalUsers,
      totalOrders,
      totalRevenue: totalRevenue._sum.total || 0,
      totalDonations: totalDonations._sum.amount || 0,
      avgRating: avgRating._avg.rating || 0,
      emailSubscribers,
      totalSocialFollowers: 0, // Deprecated - używamy socialAccountsStats
      totalVisitors: trafficStats._sum.visitors || 0,
      totalPageViews: trafficStats._sum.pageViews || 0,
      totalSessions: trafficStats._sum.sessions || 0,
      totalOffers,
      conversionRate,
      totalSubscribedUsers,
      socialAccountsStats,
    };
  } catch (error) {
    console.error("Error in getDashboardStats:", error);
    return {
      totalProducts: 0,
      totalUsers: 0,
      totalOrders: 0,
      totalRevenue: 0,
      totalDonations: 0,
      avgRating: 0,
      emailSubscribers: 0,
      totalSocialFollowers: 0,
      totalSubscribedUsers: 0,
      socialAccountsStats: {
        youtube: 0,
        facebook: 0,
        instagram: 0,
        meta: 0,
        google: 0,
        twitter: 0,
        other: 0,
      },
      totalVisitors: 0,
      totalPageViews: 0,
      totalSessions: 0,
      totalOffers: 0,
      conversionRate: "0%",
    };
  }
}

export default async function DashboardPage({
  params,
}: {
  params: { username: string };
}) {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect(`/signin?callbackUrl=/${params.username}/dashboard`);
  }

  const stats = await getDashboardStats();

  return (
    <DashboardContent
      initialStats={{
        totalProducts: stats.totalProducts,
        totalUsers: stats.totalUsers,
        totalOrders: stats.totalOrders,
        totalRevenue: stats.totalRevenue,
        totalDonations: stats.totalDonations,
        conversionRate: stats.conversionRate,
        totalSocialFollowers: stats.totalSocialFollowers,
        totalVisitors: stats.totalVisitors,
        avgRating: stats.avgRating,
        emailSubscribers: stats.emailSubscribers,
        totalPageViews: stats.totalPageViews,
        totalSessions: stats.totalSessions,
        totalOffers: stats.totalOffers,
        totalSubscribedUsers: stats.totalSubscribedUsers,
        socialAccountsStats: stats.socialAccountsStats,
      }}
      username={params.username}
    />
  );
}

