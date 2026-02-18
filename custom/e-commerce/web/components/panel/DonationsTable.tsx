"use client";

// Prisma types - will be available after running: yarn prisma generate
// @ts-ignore - Prisma types not generated yet
import type { DonationRecord } from "@prisma/client";
import { Heart, CheckCircle, Clock } from "lucide-react";

interface DonationsTableProps {
  donations: (DonationRecord & {
    foundation: { name: string; logo: string | null };
    order: {
      orderNumber: string;
      total: any;
      user: { name: string | null; email: string };
    };
  })[];
}

export default function DonationsTable({ donations }: DonationsTableProps) {
  const getStatusLabel = (status: string) => {
    const labels: Record<string, string> = {
      pending: "Oczekuje",
      transferred: "Przekazane",
      failed: "Nieudane",
    };
    return labels[status] || status;
  };

  const getStatusIcon = (status: string) => {
    if (status === "transferred") {
      return <CheckCircle className="w-4 h-4 text-green-600" />;
    }
    return <Clock className="w-4 h-4 text-yellow-600" />;
  };

  return (
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead className="bg-meo-beige-100">
          <tr>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Fundacja
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Zamówienie
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Klient
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Kwota darowizny
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Status
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Data przekazania
            </th>
          </tr>
        </thead>
        <tbody>
          {donations.map((donation) => (
            <tr
              key={donation.id}
              className="border-b border-meo-beige-200 hover:bg-rose-50"
            >
              <td className="p-4">
                <div className="flex items-center gap-3">
                  <div className="w-10 h-10 bg-rose-100 rounded-full flex items-center justify-center">
                    <Heart className="w-5 h-5 text-rose-600" />
                  </div>
                  <div className="font-medium text-meo-brown-800">
                    {donation.foundation.name}
                  </div>
                </div>
              </td>
              <td className="p-4 text-sm text-meo-brown-700 font-mono">
                {donation.order.orderNumber}
              </td>
              <td className="p-4">
                <div>
                  <div className="text-sm font-medium text-meo-brown-800">
                    {donation.order.user.name || "Brak nazwy"}
                  </div>
                  <div className="text-xs text-meo-brown-600">
                    {donation.order.user.email}
                  </div>
                </div>
              </td>
              <td className="p-4">
                <div className="font-bold text-rose-600">
                  {Number(donation.amount).toLocaleString("pl-PL")} zł
                </div>
                <div className="text-xs text-meo-brown-600">
                  z {Number(donation.order.total).toLocaleString("pl-PL")} zł
                </div>
              </td>
              <td className="p-4">
                <div className="flex items-center gap-2">
                  {getStatusIcon(donation.status)}
                  <span
                    className={`px-3 py-1 rounded-full text-xs font-medium ${
                      donation.status === "transferred"
                        ? "bg-green-100 text-green-800"
                        : donation.status === "pending"
                        ? "bg-yellow-100 text-yellow-800"
                        : "bg-red-100 text-red-800"
                    }`}
                  >
                    {getStatusLabel(donation.status)}
                  </span>
                </div>
              </td>
              <td className="p-4 text-sm text-meo-brown-600">
                {donation.transferDate
                  ? new Date(donation.transferDate).toLocaleDateString("pl-PL")
                  : "—"}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}








