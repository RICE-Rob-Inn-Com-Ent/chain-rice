import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import { Users, UserPlus, Mail, Phone } from "lucide-react";
import UsersTable from "@/components/panel/UsersTable";

async function getUsers() {
  return await prisma.user.findMany({
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
}

export default async function UzytkownicyPage() {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect("/signin?callbackUrl=/panel/uzytkownicy");
  }

  const userRole = (session.user as any)?.role || "USER";
  if (!["ADMIN", "OWNER", "SUPERADMIN"].includes(userRole)) {
    redirect("/panel");
  }

  const users = await getUsers();

  const stats = {
    total: users.length,
    customers: users.filter((u) => u.role === "CUSTOMER").length,
    admins: users.filter((u) => ["ADMIN", "OWNER", "SUPERADMIN"].includes(u.role)).length,
    active: users.filter((u) => u.lastLoginAt).length,
  };

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-meo-brown-800">Użytkownicy</h1>
          <p className="text-meo-brown-600 mt-2">
            Zarządzanie użytkownikami systemu
          </p>
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

      {/* Users Table */}
      <div className="bg-white rounded-2xl shadow-soft overflow-hidden">
        <UsersTable users={users} />
      </div>
    </div>
  );
}








