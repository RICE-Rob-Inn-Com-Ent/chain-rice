import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import { Plus, Edit2, Trash2, Package, Search } from "lucide-react";
import Link from "next/link";
import InventoryTable from "@/components/panel/InventoryTable";
import AddProductButton from "@/components/panel/AddProductButton";

async function getProducts() {
  return await prisma.product.findMany({
    orderBy: { createdAt: "desc" },
    include: {
      orderItems: {
        select: { quantity: true },
      },
    },
  });
}

export default async function MagazynPage() {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect("/signin?callbackUrl=/panel/magazyn");
  }

  const products = await getProducts();

  return (
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <div>
          <h1 className="text-3xl font-bold text-meo-brown-800">Magazyn</h1>
          <p className="text-meo-brown-600 mt-2">
            Zarządzanie asortymentem produktów
          </p>
        </div>
        <AddProductButton />
      </div>

      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">Wszystkie produkty</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {products.length}
              </p>
            </div>
            <Package className="w-8 h-8 text-meo-primary" />
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">Na stanie</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {products.filter((p) => p.stock > 0).length}
              </p>
            </div>
            <Package className="w-8 h-8 text-green-500" />
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">Wyprzedane</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {products.filter((p) => p.stock === 0).length}
              </p>
            </div>
            <Package className="w-8 h-8 text-red-500" />
          </div>
        </div>
        <div className="bg-white rounded-xl p-4 shadow-soft">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm text-meo-brown-600">Polecane</p>
              <p className="text-2xl font-bold text-meo-brown-800 mt-1">
                {products.filter((p) => p.featured).length}
              </p>
            </div>
            <Package className="w-8 h-8 text-yellow-500" />
          </div>
        </div>
      </div>

      {/* Products Table */}
      <div className="bg-white rounded-2xl shadow-soft overflow-hidden">
        <InventoryTable products={products} />
      </div>
    </div>
  );
}












































