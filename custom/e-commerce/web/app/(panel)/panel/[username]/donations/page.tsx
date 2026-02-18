import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import DonationsTable from "@/components/panel/DonationsTable";
import { Heart, TrendingUp, DollarSign } from "lucide-react";

async function getDonations() {
  return await prisma.donationRecord.findMany({
    orderBy: { createdAt: "desc" },
    include: {
      foundation: { select: { name: true, logo: true } },
      order: {
        select: {
          orderNumber: true,
          total: true,
          user: { select: { name: true, email: true } },
        },
      },
    },
  });
}

export default async function DonationsPage({
  params,
}: {
  params: { username: string };
}) {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect(`/signin?callbackUrl=/${params.username}/donations`);
  }

  const donations = await getDonations();

  const stats = {
    total: donations.length,
    transferred: donations.filter((d) => d.status === "transferred").length,
    pending: donations.filter((d) => d.status === "pending").length,
    totalAmount: donations
      .filter((d) => d.status === "transferred")
      .reduce((sum, d) => sum + Number(d.amount), 0),
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-meo-brown-800">Darowizny</h1>
        <p className="text-meo-brown-600 mt-2">
          Zarządzanie darowiznami przekazywanymi fundacjom
        </p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">Wszystkie</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {stats.total}
              </p>
            </div>
            <Heart className="w-8 h-8 text-rose-500" />
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">Przekazane</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {stats.transferred}
              </p>
            </div>
            <TrendingUp className="w-8 h-8 text-green-500" />
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">Oczekujące</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {stats.pending}
              </p>
            </div>
            <Heart className="w-8 h-8 text-yellow-500" />
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">Łączna kwota</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {stats.totalAmount.toLocaleString("pl-PL")} zł
              </p>
            </div>
            <DollarSign className="w-8 h-8 text-meo-nature" />
          </div>
        </div>
      </div>

      {/* Donations Table */}
      <div className="bg-white rounded-2xl shadow-soft overflow-hidden">
        <DonationsTable donations={donations} />
      </div>
    </div>
  );
}

