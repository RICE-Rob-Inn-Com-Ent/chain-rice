import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import { Users, UserPlus } from "lucide-react";
import UsersTable from "@/components/panel/UsersTable";

async function getUsers() {
  const users = await prisma.user.findMany({
    orderBy: { createdAt: "desc" },
    include: {
      orders: {
        select: { id: true, total: true },
      },
      _count: {
        select: { orders: true },
      },
    },
  });

  // Also get foundations and convert them to user-like format
  const foundations = await prisma.foundation.findMany({
    where: { email: { not: null } },
    orderBy: { createdAt: "desc" },
  });

  // Convert foundations to user-like objects for display
  const foundationsAsUsers = foundations.map((foundation) => ({
    id: foundation.id,
    name: foundation.name,
    email: foundation.email || "",
    role: "FOUNDATION" as const,
    createdAt: foundation.createdAt,
    updatedAt: foundation.updatedAt,
    orders: [] as { id: string; total: any }[],
    _count: { orders: 0 },
    loyaltyPoints: 0,
    totalSpent: Number(foundation.totalReceived || 0),
    lastLoginAt: null,
    phone: null,
    firstName: null,
    lastName: null,
    username: null,
    emailVerified: null,
    image: foundation.logo,
    address: null,
    preferences: null,
    dateOfBirth: null,
  }));

  // Combine users and foundations, sort by creation date
  return [...users, ...foundationsAsUsers].sort(
    (a, b) => b.createdAt.getTime() - a.createdAt.getTime()
  );
}

export default async function UsersPage({
  params,
}: {
  params: { username: string };
}) {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect(`/signin?callbackUrl=/${params.username}/users`);
  }

  const userRole = (session.user as any)?.role || "USER";
  if (!["ADMIN", "OWNER"].includes(userRole)) {
    redirect(`/${params.username}/dashboard`);
  }

  const users = await getUsers();

  const stats = {
    total: users.length,
    customers: users.filter((u) => u.role === "CUSTOMER").length,
    admins: users.filter((u) => ["ADMIN", "OWNER"].includes(u.role)).length,
    active: users.filter((u) => u.lastLoginAt).length,
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-meo-brown-800">Użytkownicy</h1>
        </div>
        <button className="bg-meo-primary text-white px-6 py-3 rounded-xl font-semibold hover:bg-meo-brown-700 transition-colors flex items-center gap-2">
          <UserPlus className="w-5 h-5" />
          Dodaj użytkownika
        </button>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">Wszyscy użytkownicy</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {stats.total}
              </p>
            </div>
            <Users className="w-8 h-8 text-meo-primary" />
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">Klienci</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {stats.customers}
              </p>
            </div>
            <Users className="w-8 h-8 text-meo-accent" />
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">Administratorzy</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {stats.admins}
              </p>
            </div>
            <Users className="w-8 h-8 text-meo-nature" />
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">Aktywni</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {stats.active}
              </p>
            </div>
            <Users className="w-8 h-8 text-green-500" />
          </div>
        </div>
      </div>

      {/* Search and Filters */}
      <div className="bg-white rounded-2xl shadow-soft p-4">
        <UsersTable users={users} />
      </div>
    </div>
  );
}

