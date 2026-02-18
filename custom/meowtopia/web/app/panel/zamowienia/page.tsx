import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import OrdersTable from "@/components/panel/OrdersTable";
import { ShoppingCart, Package, DollarSign } from "lucide-react";

async function getOrders() {
  return await prisma.order.findMany({
    orderBy: { createdAt: "desc" },
    include: {
      user: { select: { name: true, email: true } },
      items: {
        include: { product: { select: { name: true, price: true } } },
      },
      payment: { select: { status: true, paymentMethod: true } },
    },
  });
}

export default async function ZamowieniaPage() {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect("/signin?callbackUrl=/panel/zamowienia");
  }

  const orders = await getOrders();

  const stats = {
    total: orders.length,
    pending: orders.filter((o) => o.status === "PENDING").length,
    processing: orders.filter((o) => o.status === "PROCESSING").length,
    delivered: orders.filter((o) => o.status === "DELIVERED").length,
    totalRevenue: orders
      .filter((o) => o.paymentStatus === "PAID")
      .reduce((sum, o) => sum + Number(o.total), 0),
  };

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-meo-brown-800">Zamówienia</h1>
        <p className="text-meo-brown-600 mt-2">
          Zarządzanie zamówieniami klientów
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
            <ShoppingCart className="w-8 h-8 text-meo-primary" />
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
            <Package className="w-8 h-8 text-yellow-500" />
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">W realizacji</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {stats.processing}
              </p>
            </div>
            <Package className="w-8 h-8 text-blue-500" />
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">Przychód</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {stats.totalRevenue.toLocaleString("pl-PL")} zł
              </p>
            </div>
            <DollarSign className="w-8 h-8 text-green-500" />
          </div>
        </div>
      </div>

      {/* Orders Table */}
      <div className="bg-white rounded-2xl shadow-soft overflow-hidden">
        <OrdersTable orders={orders} />
      </div>
    </div>
  );
}












































