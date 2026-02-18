"use client";

import { useState, useEffect, useMemo } from "react";
import {
  Package,
  Users,
  DollarSign,
  ShoppingCart,
  TrendingUp,
  Share2,
  Target,
  Star,
  Mail,
  Eye,
  Megaphone,
  Gift,
} from "lucide-react";
import DashboardCard from "./DashboardCard";
import DateRangeFilter from "./DateRangeFilter";

interface DashboardStats {
  totalProducts: number;
  totalUsers: number;
  totalOrders: number;
  totalRevenue: number;
  totalDonations: number;
  conversionRate: string;
  totalSocialFollowers: number;
  totalVisitors: number;
  avgRating: number;
  emailSubscribers: number;
  totalPageViews: number;
  totalSessions: number;
  totalOffers: number;
  totalSubscribedUsers: number;
  socialAccountsStats: {
    youtube: number;
    facebook: number;
    instagram: number;
    meta: number;
    google: number;
    twitter: number;
    other: number;
  };
}

interface ChartDataPoint {
  date: string;
  value: number;
  comparisonValue?: number;
}

interface DashboardContentProps {
  initialStats: DashboardStats;
  username: string;
}

export default function DashboardContent({
  initialStats,
  username,
}: DashboardContentProps) {
  const [period, setPeriod] = useState<"day" | "month" | "year">("month");
  const [dateRange, setDateRange] = useState<{
    start: Date;
    end: Date;
    comparisonStart?: Date;
    comparisonEnd?: Date;
  }>({
    start: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000),
    end: new Date(),
  });
  const [chartData, setChartData] = useState<{
    orders: ChartDataPoint[];
    revenue: ChartDataPoint[];
    users: ChartDataPoint[];
    products: ChartDataPoint[];
    socialMedia: ChartDataPoint[];
    traffic: ChartDataPoint[];
    campaigns: ChartDataPoint[];
    offers: ChartDataPoint[];
  }>({
    orders: [],
    revenue: [],
    users: [],
    products: [],
    socialMedia: [],
    traffic: [],
    campaigns: [],
    offers: [],
  });
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    fetchChartData();
  }, [dateRange, period]);

  const fetchChartData = async () => {
    setLoading(true);
    try {
      const params = new URLSearchParams({
        start: dateRange.start.toISOString(),
        end: dateRange.end.toISOString(),
        period: period,
        ...(dateRange.comparisonStart && dateRange.comparisonEnd
          ? {
              comparisonStart: dateRange.comparisonStart.toISOString(),
              comparisonEnd: dateRange.comparisonEnd.toISOString(),
            }
          : {}),
      });

      const response = await fetch(`/api/dashboard/charts?${params}`);
      if (!response.ok) {
        throw new Error("Failed to fetch chart data");
      }
      const data = await response.json();
      setChartData(data);
    } catch (error) {
      console.error("Error fetching chart data:", error);
      // Don't use mock data - show empty charts instead
      setChartData({
        orders: [],
        revenue: [],
        users: [],
        products: [],
        socialMedia: [],
        traffic: [],
        campaigns: [],
        offers: [],
      });
    } finally {
      setLoading(false);
    }
  };

  // Fetch ratings and views separately
  const [ratings, setRatings] = useState<{
    overallRating: number;
    overallPercentage: number;
    sources: Array<{ name: string; rating: number; percentage: number }>;
  } | null>(null);
  const [views, setViews] = useState<{
    totalViews: number;
    sources: Array<{ platform: string; views: number }>;
  } | null>(null);

  useEffect(() => {
    fetchRatings();
    fetchViews();
  }, []);

  const fetchRatings = async () => {
    try {
      const response = await fetch("/api/dashboard/ratings");
      if (response.ok) {
        const data = await response.json();
        setRatings(data);
      }
    } catch (error) {
      console.error("Error fetching ratings:", error);
    }
  };

  const fetchViews = async () => {
    try {
      const response = await fetch("/api/dashboard/views");
      if (response.ok) {
        const data = await response.json();
        setViews(data);
      }
    } catch (error) {
      console.error("Error fetching views:", error);
    }
  };

  // Połącz przychód z darowiznami
  const totalRevenueWithDonations = Number(initialStats.totalRevenue) + Number(initialStats.totalDonations);

  const statCards = [
    {
      title: "Przychód całkowity",
      value: `${totalRevenueWithDonations.toLocaleString("pl-PL")} zł`,
      icon: DollarSign,
      color: "bg-yellow-600",
      link: `/${username}/accounting`,
      chartData: chartData.revenue,
      chartType: "line" as const,
      showComparison: !!dateRange.comparisonStart,
    },
    {
      title: "Zamówienia",
      value: initialStats.totalOrders,
      icon: ShoppingCart,
      color: "bg-purple-600",
      link: `/${username}/orders`,
      chartData: chartData.orders,
      chartType: "area" as const,
      showComparison: !!dateRange.comparisonStart,
    },
    {
      title: "Współczynnik konwersji",
      value: initialStats.conversionRate,
      icon: Target,
      color: "bg-orange-600",
      link: `/${username}/reports`,
      chartData: chartData.orders.map((d) => ({ ...d, value: d.value * 0.1 })),
      chartType: "area" as const,
      showComparison: !!dateRange.comparisonStart,
    },
    {
      title: "Użytkownicy",
      value: `${initialStats.totalUsers} użytkowników`,
      icon: Users,
      color: "bg-green-600",
      link: `/${username}/users`,
      chartData: chartData.users,
      chartType: "bar" as const,
      showComparison: !!dateRange.comparisonStart,
      isUsersCard: true,
      usersStats: {
        total: initialStats.totalUsers,
        subscribed: initialStats.totalSubscribedUsers,
        socialAccounts: initialStats.socialAccountsStats,
      },
    },
    {
      title: "Oferty",
      value: `${initialStats.totalOffers} aktywnych`,
      icon: Gift,
      color: "bg-red-600",
      link: `/${username}/offers`,
      chartData: chartData.offers,
      chartType: "area" as const,
      showComparison: !!dateRange.comparisonStart,
    },
    {
      title: "Sesje",
      value:
        initialStats.totalSessions >= 1000
          ? `${(initialStats.totalSessions / 1000).toFixed(1)}K sesji`
          : `${initialStats.totalSessions} sesji`,
      icon: TrendingUp,
      color: "bg-teal-600",
      link: `/${username}/reports`,
      chartData: chartData.traffic.map((d) => ({ ...d, value: d.value * 0.8 })),
      chartType: "line" as const,
      showComparison: !!dateRange.comparisonStart,
    },
    {
      title: "Ocena klientów",
      value: ratings
        ? `${ratings.overallPercentage}%`
        : `${Number(initialStats.avgRating).toFixed(1)}/5.0`,
      icon: Star,
      color: "bg-amber-600",
      link: `/${username}/reviews`,
      chartData: chartData.orders.map((d) => ({ ...d, value: d.value * 0.05 })),
      chartType: "bar" as const,
      showComparison: !!dateRange.comparisonStart,
    },
  ];

  return (
    <div className="space-y-6">
      {/* Date Range Filter */}
      <DateRangeFilter
        onDateRangeChange={setDateRange}
        onPeriodChange={setPeriod}
        defaultPeriod={period}
      />

      {/* Stat Cards with Charts - Max 2 columns */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {statCards.map((stat) => {
          const cardProps: any = {
            key: stat.title,
            title: stat.title,
            value: stat.value,
            icon: stat.icon,
            color: stat.color,
            link: stat.link,
            chartData: stat.chartData,
            chartType: stat.chartType,
            showComparison: stat.showComparison,
            period: period,
          };
          if ('subtitle' in stat && typeof stat.subtitle === 'string') {
            cardProps.subtitle = stat.subtitle;
          }
          if ('isUsersCard' in stat) {
            cardProps.isUsersCard = stat.isUsersCard;
          }
          if ('usersStats' in stat) {
            cardProps.usersStats = stat.usersStats;
          }
          return <DashboardCard {...cardProps} />;
        })}
      </div>
    </div>
  );
}

