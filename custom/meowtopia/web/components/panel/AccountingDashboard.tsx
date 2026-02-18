"use client";

import { DollarSign, Heart, Calendar } from "lucide-react";

interface AccountingDashboardProps {
  data: {
    totalRevenue: number;
    totalDonations: number;
    monthlyRevenue: number;
    monthlyDonations: number;
    orders: any[];
    donations: any[];
  };
}

export default function AccountingDashboard({ data }: AccountingDashboardProps) {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Recent Orders */}
      <div className="bg-white rounded-2xl p-6 shadow-soft">
        <h2 className="text-xl font-bold text-meo-brown-800 mb-4 flex items-center gap-2">
          <DollarSign className="w-5 h-5" />
          Ostatnie płatności
        </h2>
        <div className="space-y-3">
          {data.orders.slice(0, 5).map((order) => (
            <div
              key={order.id}
              className="flex items-center justify-between p-3 bg-meo-beige-50 rounded-xl"
            >
              <div>
                <p className="font-medium text-meo-brown-800">
                  {order.user.name || order.user.email}
                </p>
                <p className="text-sm text-meo-brown-600">
                  {order.orderNumber}
                </p>
              </div>
              <div className="text-right">
                <p className="font-semibold text-meo-brown-800">
                  {Number(order.total).toLocaleString("pl-PL")} zł
                </p>
                <p className="text-xs text-meo-brown-600">
                  {new Date(order.createdAt).toLocaleDateString("pl-PL")}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Recent Donations */}
      <div className="bg-white rounded-2xl p-6 shadow-soft">
        <h2 className="text-xl font-bold text-meo-brown-800 mb-4 flex items-center gap-2">
          <Heart className="w-5 h-5" />
          Ostatnie darowizny
        </h2>
        <div className="space-y-3">
          {data.donations.slice(0, 5).map((donation) => (
            <div
              key={donation.id}
              className="flex items-center justify-between p-3 bg-rose-50 rounded-xl"
            >
              <div>
                <p className="font-medium text-meo-brown-800">
                  {donation.foundation.name}
                </p>
                <p className="text-sm text-meo-brown-600">
                  Zamówienie: {donation.order.orderNumber}
                </p>
              </div>
              <div className="text-right">
                <p className="font-semibold text-rose-600">
                  {Number(donation.amount).toLocaleString("pl-PL")} zł
                </p>
                <p className="text-xs text-meo-brown-600">
                  {donation.transferDate
                    ? new Date(donation.transferDate).toLocaleDateString("pl-PL")
                    : "Oczekuje"}
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}












































