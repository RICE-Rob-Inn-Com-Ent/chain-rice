import { getServerSession } from "next-auth";
import { authOptions } from "@/lib/auth";
import { prisma } from "@/lib/prisma";
import { redirect } from "next/navigation";
import { Search, SlidersHorizontal, Plus, Gift } from "lucide-react";
import InventoryTable from "@/components/panel/InventoryTable";
import AddProductModal from "@/components/panel/AddProductModal";
import CreateOfferModal from "@/components/panel/CreateOfferModal";

async function getProducts() {
  return await prisma.product.findMany({
    orderBy: { createdAt: "desc" },
    include: {
      category: true,
      orderItems: {
        select: { quantity: true },
      },
      bundleProducts: {
        include: {
          product: {
            select: {
              id: true,
              name: true,
              stock: true,
              active: true,
            },
          },
        },
      },
    },
  });
}

export default async function InventoryPage({
  params,
}: {
  params: { username: string };
}) {
  const session = await getServerSession(authOptions);
  if (!session) {
    redirect(`/signin?callbackUrl=/${params.username}/inventory`);
  }

  const products = await getProducts();
  
  // Debug: log product images
  if (products.length > 0) {
    console.log('Products with images:', products.map(p => ({
      name: p.name,
      imagesCount: p.images.length,
      images: p.images
    })));
  }

  return (
    <div className="space-y-6">
      {/* Search and Filters */}
      <div className="flex items-center gap-4">
        <div className="flex-1 relative">
          <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-gray-400 w-5 h-5" />
          <input
            type="text"
            placeholder="Szukaj produktów, kategorii, SKU..."
            className="w-full pl-10 pr-4 py-3 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 focus:border-transparent bg-white"
          />
        </div>
        <button className="flex items-center justify-center w-11 h-11 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors bg-white">
          <SlidersHorizontal className="w-5 h-5 text-gray-600" />
        </button>
        <CreateOfferModal products={products} />
        <AddProductModal />
      </div>

      {/* Products Table */}
      <div className="bg-white rounded-2xl shadow-soft overflow-hidden">
        <InventoryTable products={products} />
      </div>
    </div>
  );
}

