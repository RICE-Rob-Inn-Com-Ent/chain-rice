import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import {
  Package,
  Users,
  DollarSign,
  Heart,
  TrendingUp,
  ShoppingCart,
  Share2,
  Target,
  Star,
  Mail,
} from "lucide-react";
import Link from "next/link";

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
      socialMediaStats,
      trafficStats,
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
      prisma.socialMediaStats.findMany({
        where: {
          platform: { in: ["facebook", "instagram", "twitter"] },
        },
      }).catch(() => []), // Fallback do pustej tablicy jeśli błąd
      prisma.websiteTraffic.aggregate({
        where: {
          date: {
            gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000), // ostatnie 30 dni
          },
        },
        _sum: {
          visitors: true,
          pageViews: true,
          sessions: true,
        },
      }).catch(() => ({ _sum: { visitors: 0, pageViews: 0, sessions: 0 } })), // Fallback jeśli błąd
    ]);

    // Oblicz sumę followers z wszystkich platform social media
    const totalSocialFollowers = socialMediaStats.reduce(
      (sum, stat) => sum + stat.followers,
      0
    );

    // Oblicz conversion rate
    const conversionRate =
      totalUsers > 0
        ? ((totalOrders / totalUsers) * 100).toFixed(1) + "%"
        : "0%";

    return {
      totalProducts,
      totalUsers,
      totalOrders,
      totalRevenue: totalRevenue._sum.total || 0,
      totalDonations: totalDonations._sum.amount || 0,
      avgRating: avgRating._avg.rating || 0,
      emailSubscribers,
      totalSocialFollowers,
      totalVisitors: trafficStats._sum.visitors || 0,
      conversionRate,
    };
  } catch (error) {
    console.error("Error in getDashboardStats:", error);
    // Zwróć wartości domyślne w przypadku błędu
    return {
      totalProducts: 0,
      totalUsers: 0,
      totalOrders: 0,
      totalRevenue: 0,
      totalDonations: 0,
      avgRating: 0,
      emailSubscribers: 0,
      totalSocialFollowers: 0,
      totalVisitors: 0,
      conversionRate: "0%",
    };
  }
}

export default async function PanelDashboard() {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect("/signin?callbackUrl=/panel");
  }

  const stats = await getDashboardStats();

  const statCards = [
    {
      title: "Produkty",
      value: stats.totalProducts,
      icon: Package,
      color: "bg-meo-primary",
      link: "/panel/magazyn",
    },
    {
      title: "Użytkownicy",
      value: stats.totalUsers,
      icon: Users,
      color: "bg-meo-accent",
      link: "/panel/uzytkownicy",
    },
    {
      title: "Zamówienia",
      value: stats.totalOrders,
      icon: ShoppingCart,
      color: "bg-meo-nature",
      link: "/panel/zamowienia",
    },
    {
      title: "Przychód",
      value: `${Number(stats.totalRevenue).toLocaleString("pl-PL")} zł`,
      icon: DollarSign,
      color: "bg-meo-brown-600",
      link: "/panel/ksiegowosc",
    },
    {
      title: "Darowizny",
      value: `${Number(stats.totalDonations).toLocaleString("pl-PL")} zł`,
      icon: Heart,
      color: "bg-rose-500",
      link: "/panel/ksiegowosc/darowizny",
    },
    {
      title: "Wzrost",
      value: "+12.5%",
      icon: TrendingUp,
      color: "bg-green-500",
      link: "/panel/raporty",
    },
    {
      title: "Social Media",
      value:
        stats.totalSocialFollowers >= 1000
          ? `${(stats.totalSocialFollowers / 1000).toFixed(1)}K followers`
          : `${stats.totalSocialFollowers} followers`,
      icon: Share2,
      color: "bg-pink-500",
      link: "/panel/raporty",
    },
    {
      title: "Ruch na stronie",
      value:
        stats.totalVisitors >= 1000
          ? `${(stats.totalVisitors / 1000).toFixed(1)}K odwiedzin`
          : `${stats.totalVisitors} odwiedzin`,
      icon: TrendingUp,
      color: "bg-blue-500",
      link: "/panel/raporty",
    },
    {
      title: "Współczynnik konwersji",
      value: stats.conversionRate,
      icon: Target,
      color: "bg-orange-500",
      link: "/panel/raporty",
    },
    {
      title: "Zadowolenie klientów",
      value: `${Number(stats.avgRating).toFixed(1)}/5.0`,
      icon: Star,
      color: "bg-yellow-500",
      link: "/panel/raporty",
    },
    {
      title: "Kampanie emailowe",
      value: stats.emailSubscribers,
      icon: Mail,
      color: "bg-indigo-500",
      link: "/panel/raporty",
    },
  ];

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-meo-brown-800">Dashboard</h1>
        <p className="text-meo-brown-600 mt-2">
          Przegląd działalności MeoWTopia
        </p>
      </div>

      {/* Stat Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {statCards.map((stat) => {
          const Icon = stat.icon;
          return (
            <Link
              key={stat.title}
              href={stat.link}
              className="bg-white rounded-2xl p-6 shadow-soft hover:shadow-medium transition-all duration-300 hover:scale-105"
            >
              <div className="flex items-center justify-between mb-4">
                <div className={`${stat.color} p-3 rounded-xl text-white`}>
                  <Icon className="w-6 h-6" />
                </div>
                <span className="text-sm text-meo-brown-600">Zobacz →</span>
              </div>
              <h3 className="text-2xl font-bold text-meo-brown-800 mb-1">
                {stat.value}
              </h3>
              <p className="text-meo-brown-600">{stat.title}</p>
            </Link>
          );
        })}
      </div>
    </div>
  );
}




