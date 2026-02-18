"use client";

import { useState, useMemo } from "react";
// Prisma types - will be available after running: yarn prisma generate
// @ts-ignore - Prisma types not generated yet
import type { User } from "@prisma/client";
import { Edit2, Mail, Phone, ShoppingCart, Search, X, Filter } from "lucide-react";

interface UsersTableProps {
  users: (User & {
    orders: { id: string; total: any }[];
    _count: { orders: number };
    totalSpent?: number;
    role?: string;
  })[];
}

export default function UsersTable({ users }: UsersTableProps) {
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedRole, setSelectedRole] = useState<string>("all");

  // Get unique roles from users
  const availableRoles = useMemo(() => {
    const roles = new Set(users.map((u) => u.role || "USER"));
    return Array.from(roles).sort();
  }, [users]);

  // Filter users by search query and role
  const filteredUsers = useMemo(() => {
    let filtered = users;

    // Filter by role
    if (selectedRole !== "all") {
      filtered = filtered.filter((u) => (u.role || "USER") === selectedRole);
    }

    // Filter by search query
    if (searchQuery.trim()) {
      const query = searchQuery.trim().toLowerCase();
      filtered = filtered.filter((u) => {
        const name = (u.name || "").toLowerCase();
        const email = (u.email || "").toLowerCase();
        const phone = (u.phone || "").toLowerCase();
        return name.includes(query) || email.includes(query) || phone.includes(query);
      });
    }

    return filtered;
  }, [users, searchQuery, selectedRole]);

  const getRoleLabel = (role: string) => {
    const labels: Record<string, string> = {
      USER: "Użytkownik",
      CUSTOMER: "Użytkownik", // Legacy support
      VOLUNTEER: "Wolontariusz",
      ADMIN: "Administrator",
      MANAGER: "Manager",
      OWNER: "Właściciel",
      FOUNDATION: "Fundacja",
      ARTIST: "Artysta",
    };
    return labels[role] || role;
  };

  const getRoleColor = (role: string) => {
    const colors: Record<string, string> = {
      USER: "bg-meo-accent/10 text-meo-accent",
      CUSTOMER: "bg-meo-accent/10 text-meo-accent", // Legacy support
      VOLUNTEER: "bg-blue-100 text-blue-800",
      ADMIN: "bg-meo-primary/10 text-meo-primary",
      MANAGER: "bg-meo-nature/10 text-meo-nature",
      OWNER: "bg-purple-100 text-purple-800",
      FOUNDATION: "bg-green-100 text-green-800",
      ARTIST: "bg-purple-100 text-purple-800",
    };
    return colors[role] || "bg-gray-100 text-gray-800";
  };

  const getTotalSpent = (user: User & { orders: { total: any }[]; totalSpent?: number; role?: string }) => {
    // For foundations, use totalReceived (mapped as totalSpent)
    if (user.role === "FOUNDATION" && user.totalSpent !== undefined) {
      return user.totalSpent;
    }
    // For regular users, calculate from orders
    return user.orders.reduce(
      (sum, order) => sum + Number(order.total || 0),
      0
    );
  };

  return (
    <div className="space-y-4">
      {/* Search and Filters */}
      <div className="flex flex-col sm:flex-row gap-4 items-start sm:items-center">
        {/* Search */}
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-meo-brown-400 w-5 h-5" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Wyszukaj: imię, email, telefon..."
            className="w-full pl-10 pr-10 py-2.5 border border-meo-beige-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-meo-primary focus:border-transparent bg-white text-meo-brown-800 placeholder:text-meo-brown-400"
          />
          {searchQuery && (
            <button
              type="button"
              onClick={() => setSearchQuery("")}
              className="absolute right-3 top-1/2 transform -translate-y-1/2 text-meo-brown-400 hover:text-meo-brown-600"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>

        {/* Role Filter */}
        <div className="flex items-center gap-2">
          <Filter className="w-5 h-5 text-meo-brown-600" />
          <select
            value={selectedRole}
            onChange={(e) => setSelectedRole(e.target.value)}
            className="px-4 py-2.5 border border-meo-beige-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-meo-primary focus:border-transparent bg-white text-meo-brown-800 cursor-pointer"
          >
            <option value="all">Wszystkie role</option>
            {availableRoles.map((role) => (
              <option key={role} value={role}>
                {getRoleLabel(role)}
              </option>
            ))}
          </select>
        </div>
      </div>

      {/* Results count */}
      {filteredUsers.length !== users.length && (
        <div className="text-sm text-meo-brown-600">
          Znaleziono {filteredUsers.length} z {users.length} użytkowników
        </div>
      )}

      {/* Table */}
      <div className="overflow-x-auto">
        <table className="w-full">
        <thead className="bg-meo-beige-100">
          <tr>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Użytkownik
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Email
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Rola
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Zamówienia
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Wydano
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Punkty
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Akcje
            </th>
          </tr>
        </thead>
        <tbody>
          {filteredUsers.length === 0 ? (
            <tr>
              <td colSpan={7} className="p-8 text-center text-meo-brown-600">
                Brak użytkowników spełniających kryteria wyszukiwania
              </td>
            </tr>
          ) : (
            filteredUsers.map((user) => (
            <tr
              key={user.id}
              className="border-b border-meo-beige-200 hover:bg-meo-beige-50"
            >
              <td className="p-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-meo-primary rounded-full flex items-center justify-center text-white font-semibold">
                    {(user.name || user.email || "U")[0].toUpperCase()}
                  </div>
                  <div>
                    <div className="font-medium text-meo-brown-800">
                      {user.name || "Brak nazwy"}
                    </div>
                    {user.phone && (
                      <div className="text-xs text-meo-brown-600 flex items-center gap-1">
                        <Phone className="w-3 h-3" />
                        {user.phone}
                      </div>
                    )}
                  </div>
                </div>
              </td>
              <td className="p-4">
                <div className="flex items-center gap-2 text-meo-brown-700">
                  <Mail className="w-4 h-4" />
                  {user.email}
                </div>
              </td>
              <td className="p-4">
                <span
                  className={`px-3 py-1 rounded-full text-xs font-medium ${getRoleColor(
                    user.role
                  )}`}
                >
                  {getRoleLabel(user.role)}
                </span>
              </td>
              <td className="p-4 text-meo-brown-700">
                <div className="flex items-center gap-2">
                  <ShoppingCart className="w-4 h-4" />
                  {user._count.orders}
                </div>
              </td>
              <td className="p-4 font-semibold text-meo-brown-800">
                {user.role === "FOUNDATION" 
                  ? `${getTotalSpent(user).toLocaleString("pl-PL")} zł (otrzymano)`
                  : `${getTotalSpent(user).toLocaleString("pl-PL")} zł`}
              </td>
              <td className="p-4 text-meo-brown-700">
                {user.loyaltyPoints || 0} pkt
              </td>
              <td className="p-4">
                <button
                  className="p-2 text-meo-brown-600 hover:bg-meo-beige-100 rounded-lg transition-colors"
                  title="Edytuj"
                >
                  <Edit2 className="w-4 h-4" />
                </button>
              </td>
            </tr>
            ))
          )}
        </tbody>
      </table>
      </div>
    </div>
  );
}








