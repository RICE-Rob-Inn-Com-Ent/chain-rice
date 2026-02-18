"use client";

// Prisma types - will be available after running: yarn prisma generate
// @ts-ignore - Prisma types not generated yet
import type { Order } from "@prisma/client";
import { Eye, Edit2 } from "lucide-react";

interface OrdersTableProps {
  orders: (Order & {
    user: { name: string | null; email: string };
    items: { product: { name: string; price: any } }[];
    payment: { status: string; paymentMethod: string } | null;
  })[];
}

export default function OrdersTable({ orders }: OrdersTableProps) {
  const getStatusLabel = (status: string) => {
    const labels: Record<string, string> = {
      PENDING: "Oczekujące",
      CONFIRMED: "Potwierdzone",
      PROCESSING: "W realizacji",
      SHIPPED: "Wysłane",
      DELIVERED: "Dostarczone",
      CANCELLED: "Anulowane",
      REFUNDED: "Zwrócone",
    };
    return labels[status] || status;
  };

  const getStatusColor = (status: string) => {
    const colors: Record<string, string> = {
      PENDING: "bg-yellow-100 text-yellow-800",
      CONFIRMED: "bg-blue-100 text-blue-800",
      PROCESSING: "bg-purple-100 text-purple-800",
      SHIPPED: "bg-indigo-100 text-indigo-800",
      DELIVERED: "bg-green-100 text-green-800",
      CANCELLED: "bg-red-100 text-red-800",
      REFUNDED: "bg-gray-100 text-gray-800",
    };
    return colors[status] || "bg-gray-100 text-gray-800";
  };

  return (
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead className="bg-meo-beige-100">
          <tr>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Numer
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Klient
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Produkty
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Wartość
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Darowizna
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Status
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Płatność
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Data
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Akcje
            </th>
          </tr>
        </thead>
        <tbody>
          {orders.map((order) => (
            <tr
              key={order.id}
              className="border-b border-meo-beige-200 hover:bg-meo-beige-50"
            >
              <td className="p-4 text-sm text-meo-brown-700 font-mono">
                {order.orderNumber}
              </td>
              <td className="p-4">
                <div>
                  <div className="font-medium text-meo-brown-800">
                    {order.user.name || "Brak nazwy"}
                  </div>
                  <div className="text-xs text-meo-brown-600">
                    {order.user.email}
                  </div>
                </div>
              </td>
              <td className="p-4 text-sm text-meo-brown-700">
                {order.items.length} produkt(ów)
              </td>
              <td className="p-4 font-semibold text-meo-brown-800">
                {Number(order.total).toLocaleString("pl-PL")} zł
              </td>
              <td className="p-4 text-sm text-rose-600 font-medium">
                {Number(order.donationAmount).toLocaleString("pl-PL")} zł
              </td>
              <td className="p-4">
                <span
                  className={`px-3 py-1 rounded-full text-xs font-medium ${getStatusColor(
                    order.status
                  )}`}
                >
                  {getStatusLabel(order.status)}
                </span>
              </td>
              <td className="p-4">
                <span
                  className={`px-3 py-1 rounded-full text-xs font-medium ${
                    order.paymentStatus === "PAID"
                      ? "bg-green-100 text-green-800"
                      : "bg-yellow-100 text-yellow-800"
                  }`}
                >
                  {order.paymentStatus}
                </span>
              </td>
              <td className="p-4 text-sm text-meo-brown-600">
                {new Date(order.createdAt).toLocaleDateString("pl-PL")}
              </td>
              <td className="p-4">
                <div className="flex items-center gap-2">
                  <button
                    className="p-2 text-meo-brown-600 hover:bg-meo-beige-100 rounded-lg transition-colors"
                    title="Podgląd"
                  >
                    <Eye className="w-4 h-4" />
                  </button>
                  <button
                    className="p-2 text-meo-brown-600 hover:bg-meo-beige-100 rounded-lg transition-colors"
                    title="Edytuj"
                  >
                    <Edit2 className="w-4 h-4" />
                  </button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}








