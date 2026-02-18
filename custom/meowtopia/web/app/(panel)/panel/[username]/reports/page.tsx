import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import { FileText, Download, Calendar, TrendingUp } from "lucide-react";
import ReportsDashboard from "@/components/panel/ReportsDashboard";

async function getReportsData() {
  const currentYear = new Date().getFullYear();
  const yearStart = new Date(currentYear, 0, 1);
  const yearEnd = new Date(currentYear, 11, 31);

  const [
    yearlyOrders,
    yearlyRevenue,
    yearlyDonations,
    monthlyData,
    topProducts,
    topCustomers,
  ] = await Promise.all([
    prisma.order.count({
      where: {
        paymentStatus: "PAID",
        createdAt: { gte: yearStart, lte: yearEnd },
      },
    }),
    prisma.order.aggregate({
      _sum: { total: true },
      where: {
        paymentStatus: "PAID",
        createdAt: { gte: yearStart, lte: yearEnd },
      },
    }),
    prisma.donationRecord.aggregate({
      _sum: { amount: true },
      where: {
        status: "transferred",
        transferDate: { gte: yearStart, lte: yearEnd },
      },
    }),
    // Monthly data for last 12 months
    Promise.all(
      Array.from({ length: 12 }, (_, i) => {
        const monthStart = new Date(currentYear, 11 - i, 1);
        const monthEnd = new Date(currentYear, 12 - i, 0);
        return prisma.order.aggregate({
          _sum: { total: true },
          where: {
            paymentStatus: "PAID",
            createdAt: { gte: monthStart, lte: monthEnd },
          },
        });
      })
    ),
    prisma.orderItem.groupBy({
      by: ["productId"],
      _sum: { quantity: true, total: true },
      orderBy: { _sum: { quantity: "desc" } },
      take: 10,
    }),
    prisma.user.findMany({
      where: {
        orders: { some: { paymentStatus: "PAID" } },
      },
      include: {
        orders: {
          where: { paymentStatus: "PAID" },
          select: { total: true },
        },
      },
      orderBy: { totalSpent: "desc" },
      take: 10,
    }),
  ]);

  return {
    yearlyOrders,
    yearlyRevenue: yearlyRevenue._sum.total || 0,
    yearlyDonations: yearlyDonations._sum.amount || 0,
    monthlyData: monthlyData.map((m) => m._sum.total || 0),
    topProducts,
    topCustomers,
  };
}

export default async function ReportsPage({
  params,
}: {
  params: { username: string };
}) {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect(`/signin?callbackUrl=/${params.username}/reports`);
  }

  const data = await getReportsData();

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-meo-brown-800">Raporty</h1>
          <p className="text-meo-brown-600 mt-2">
            Analiza działalności i statystyki
          </p>
        </div>
        <button className="bg-meo-primary text-white px-6 py-3 rounded-xl font-semibold hover:bg-meo-brown-700 transition-colors flex items-center gap-2">
          <Download className="w-5 h-5" />
          Eksportuj raport
        </button>
      </div>

      {/* Summary Cards */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-xl p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <FileText className="w-8 h-8 text-meo-primary" />
            <Calendar className="w-5 h-5 text-meo-brown-600" />
          </div>
          <p className="text-sm text-meo-brown-600">Zamówienia (ten rok)</p>
          <p className="text-2xl font-bold text-meo-brown-800 mt-2">
            {data.yearlyOrders}
          </p>
        </div>

        <div className="bg-white rounded-xl p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <TrendingUp className="w-8 h-8 text-meo-accent" />
            <Calendar className="w-5 h-5 text-meo-brown-600" />
          </div>
          <p className="text-sm text-meo-brown-600">Przychód (ten rok)</p>
          <p className="text-2xl font-bold text-meo-brown-800 mt-2">
            {Number(data.yearlyRevenue).toLocaleString("pl-PL")} zł
          </p>
        </div>

        <div className="bg-white rounded-xl p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <FileText className="w-8 h-8 text-rose-500" />
            <Calendar className="w-5 h-5 text-meo-brown-600" />
          </div>
          <p className="text-sm text-meo-brown-600">Darowizny (ten rok)</p>
          <p className="text-2xl font-bold text-meo-brown-800 mt-2">
            {Number(data.yearlyDonations).toLocaleString("pl-PL")} zł
          </p>
        </div>
      </div>

      <ReportsDashboard data={data} />
    </div>
  );
}

