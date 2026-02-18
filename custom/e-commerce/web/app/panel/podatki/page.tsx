import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import TaxCalculator from "@/components/panel/TaxCalculator";
import { Calculator, FileText, AlertCircle } from "lucide-react";

async function getTaxData() {
  const currentYear = new Date().getFullYear();
  const yearStart = new Date(currentYear, 0, 1);
  const yearEnd = new Date(currentYear, 11, 31);

  const [
    yearlyRevenue,
    yearlyDonations,
    orders,
  ] = await Promise.all([
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
    prisma.order.findMany({
      where: {
        paymentStatus: "PAID",
        createdAt: { gte: yearStart, lte: yearEnd },
      },
      select: {
        total: true,
        donationAmount: true,
        createdAt: true,
      },
    }),
  ]);

  return {
    yearlyRevenue: yearlyRevenue._sum.total || 0,
    yearlyDonations: yearlyDonations._sum.amount || 0,
    orders,
  };
}

export default async function PodatkiPage() {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect("/signin?callbackUrl=/panel/podatki");
  }

  const userRole = (session.user as any)?.role || "USER";
  if (!["ADMIN", "OWNER", "SUPERADMIN"].includes(userRole)) {
    redirect("/panel");
  }

  const taxData = await getTaxData();

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-meo-brown-800">Podatki</h1>
        <p className="text-meo-brown-600 mt-2">
          Kalkulacja podatków zgodnie z prawem polskim dla fundacji
        </p>
      </div>

      {/* Info Alert */}
      <div className="bg-blue-50 border border-blue-200 rounded-xl p-4 flex items-start gap-3">
        <AlertCircle className="w-5 h-5 text-blue-600 mt-0.5" />
        <div>
          <h3 className="font-semibold text-blue-900 mb-1">
            Informacja o podatkach dla fundacji
          </h3>
          <p className="text-sm text-blue-800">
            Fundacje w Polsce korzystają ze zwolnień podatkowych. Darowizny na
            cele pożytku publicznego są zwolnione z VAT. System automatycznie
            kalkuluje podatki zgodnie z aktualnymi przepisami prawa.
          </p>
        </div>
      </div>

      <TaxCalculator taxData={taxData} />
    </div>
  );
}








