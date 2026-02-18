import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import { DollarSign, TrendingUp, TrendingDown, Heart } from "lucide-react";
import AccountingDashboard from "@/components/panel/AccountingDashboard";

async function getAccountingData() {
  const [
    totalRevenue,
    totalDonations,
    monthlyRevenue,
    monthlyDonations,
    orders,
    donations,
  ] = await Promise.all([
    prisma.order.aggregate({
      _sum: { total: true },
      where: { paymentStatus: "PAID" },
    }),
    prisma.donationRecord.aggregate({
      _sum: { amount: true },
      where: { status: "transferred" },
    }),
    prisma.order.aggregate({
      _sum: { total: true },
      where: {
        paymentStatus: "PAID",
        createdAt: {
          gte: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
        },
      },
    }),
    prisma.donationRecord.aggregate({
      _sum: { amount: true },
      where: {
        status: "transferred",
        createdAt: {
          gte: new Date(new Date().getFullYear(), new Date().getMonth(), 1),
        },
      },
    }),
    prisma.order.findMany({
      take: 10,
      where: { paymentStatus: "PAID" },
      orderBy: { createdAt: "desc" },
      include: {
        user: { select: { name: true, email: true } },
        donationRecord: { include: { foundation: { select: { name: true } } } },
      },
    }),
    prisma.donationRecord.findMany({
      take: 10,
      where: { status: "transferred" },
      orderBy: { transferDate: "desc" },
      include: {
        foundation: { select: { name: true } },
        order: { select: { orderNumber: true, total: true } },
      },
    }),
  ]);

  return {
    totalRevenue: totalRevenue._sum.total || 0,
    totalDonations: totalDonations._sum.amount || 0,
    monthlyRevenue: monthlyRevenue._sum.total || 0,
    monthlyDonations: monthlyDonations._sum.amount || 0,
    orders,
    donations,
  };
}

export default async function KsiegowoscPage() {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect("/signin?callbackUrl=/panel/ksiegowosc");
  }

  const userRole = (session.user as any)?.role || "USER";
  if (!["ADMIN", "OWNER", "SUPERADMIN"].includes(userRole)) {
    redirect("/panel");
  }

  const data = await getAccountingData();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-meo-brown-800">Księgowość</h1>
        <p className="text-meo-brown-600 mt-2">
          Zarządzanie finansami i darowiznami fundacji
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <DollarSign className="w-8 h-8 text-meo-primary" />
            <TrendingUp className="w-5 h-5 text-green-500" />
          </div>
          <p className="text-sm text-meo-brown-600">Całkowity przychód</p>
          <p className="text-2xl font-bold text-meo-brown-800 mt-2">
            {Number(data.totalRevenue).toLocaleString("pl-PL")} zł
          </p>
        </div>

        <div className="bg-white rounded-xl p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <Heart className="w-8 h-8 text-rose-500" />
            <TrendingUp className="w-5 h-5 text-green-500" />
          </div>
          <p className="text-sm text-meo-brown-600">Przekazane darowizny</p>
          <p className="text-2xl font-bold text-meo-brown-800 mt-2">
            {Number(data.totalDonations).toLocaleString("pl-PL")} zł
          </p>
        </div>

        <div className="bg-white rounded-xl p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <DollarSign className="w-8 h-8 text-meo-accent" />
            <TrendingUp className="w-5 h-5 text-green-500" />
          </div>
          <p className="text-sm text-meo-brown-600">Przychód (ten miesiąc)</p>
          <p className="text-2xl font-bold text-meo-brown-800 mt-2">
            {Number(data.monthlyRevenue).toLocaleString("pl-PL")} zł
          </p>
        </div>

        <div className="bg-white rounded-xl p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <Heart className="w-8 h-8 text-meo-nature" />
            <TrendingUp className="w-5 h-5 text-green-500" />
          </div>
          <p className="text-sm text-meo-brown-600">Darowizny (ten miesiąc)</p>
          <p className="text-2xl font-bold text-meo-brown-800 mt-2">
            {Number(data.monthlyDonations).toLocaleString("pl-PL")} zł
          </p>
        </div>
      </div>

      <AccountingDashboard data={data} />
    </div>
  );
}








