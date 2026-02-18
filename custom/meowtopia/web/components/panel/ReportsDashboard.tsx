"use client";

import { TrendingUp, Package, Users } from "lucide-react";

interface ReportsDashboardProps {
  data: {
    yearlyOrders: number;
    yearlyRevenue: number;
    yearlyDonations: number;
    monthlyData: number[];
    topProducts: any[];
    topCustomers: any[];
  };
}

export default function ReportsDashboard({ data }: ReportsDashboardProps) {
  const months = [
    "Sty", "Lut", "Mar", "Kwi", "Maj", "Cze",
    "Lip", "Sie", "Wrz", "Paź", "Lis", "Gru"
  ];

  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
      {/* Monthly Revenue Chart */}
      <div className="bg-white rounded-2xl p-6 shadow-soft">
        <h2 className="text-xl font-bold text-meo-brown-800 mb-4">
          Przychód miesięczny
        </h2>
        <div className="space-y-3">
          {data.monthlyData.map((revenue, index) => {
            const maxRevenue = Math.max(...data.monthlyData);
            const percentage = maxRevenue > 0 ? (revenue / maxRevenue) * 100 : 0;
            return (
              <div key={index} className="space-y-1">
                <div className="flex justify-between text-sm">
                  <span className="text-meo-brown-700">
                    {months[11 - index]}
                  </span>
                  <span className="font-semibold text-meo-brown-800">
                    {revenue.toLocaleString("pl-PL")} zł
                  </span>
                </div>
                <div className="w-full bg-meo-beige-200 rounded-full h-2">
                  <div
                    className="bg-meo-primary h-2 rounded-full transition-all"
                    style={{ width: `${percentage}%` }}
                  />
                </div>
              </div>
            );
          })}
        </div>
      </div>

      {/* Top Products */}
      <div className="bg-white rounded-2xl p-6 shadow-soft">
        <h2 className="text-xl font-bold text-meo-brown-800 mb-4 flex items-center gap-2">
          <Package className="w-5 h-5" />
          Najlepiej sprzedające się produkty
        </h2>
        <div className="space-y-3">
          {data.topProducts.slice(0, 5).map((item, index) => (
            <div
              key={item.productId}
              className="flex items-center justify-between p-3 bg-meo-beige-50 rounded-xl"
            >
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 bg-meo-primary rounded-full flex items-center justify-center text-white font-bold text-sm">
                  {index + 1}
                </div>
                <div>
                  <p className="font-medium text-meo-brown-800">
                    Produkt #{item.productId.slice(0, 8)}
                  </p>
                  <p className="text-xs text-meo-brown-600">
                    {item._sum.quantity} szt. sprzedanych
                  </p>
                </div>
              </div>
              <div className="text-right">
                <p className="font-semibold text-meo-brown-800">
                  {Number(item._sum.total || 0).toLocaleString("pl-PL")} zł
                </p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Top Customers */}
      <div className="bg-white rounded-2xl p-6 shadow-soft lg:col-span-2">
        <h2 className="text-xl font-bold text-meo-brown-800 mb-4 flex items-center gap-2">
          <Users className="w-5 h-5" />
          Najlepsi klienci
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
          {data.topCustomers.slice(0, 5).map((customer, index) => {
            const totalSpent = customer.orders.reduce(
              (sum, order) => sum + Number(order.total || 0),
              0
            );
            return (
              <div
                key={customer.id}
                className="p-4 bg-meo-beige-50 rounded-xl text-center"
              >
                <div className="w-12 h-12 bg-meo-primary rounded-full flex items-center justify-center text-white font-bold mx-auto mb-2">
                  {(customer.name || customer.email || "U")[0].toUpperCase()}
                </div>
                <p className="font-medium text-meo-brown-800 text-sm mb-1">
                  {customer.name || customer.email?.split("@")[0] || "Klient"}
                </p>
                <p className="text-xs text-meo-brown-600 mb-2">
                  {customer.orders.length} zamówień
                </p>
                <p className="font-bold text-meo-brown-800">
                  {totalSpent.toLocaleString("pl-PL")} zł
                </p>
              </div>
            );
          })}
        </div>
      </div>
    </div>
  );
}












































