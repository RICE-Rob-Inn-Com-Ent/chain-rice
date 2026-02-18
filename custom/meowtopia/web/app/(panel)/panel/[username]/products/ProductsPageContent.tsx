"use client";

import { useState } from "react";
import { Search, SlidersHorizontal } from "lucide-react";
import { Icon } from "@iconify/react";
import InventoryTable from "@/components/panel/InventoryTable";
import AddProductModal from "@/components/panel/AddProductModal";
import OfferSettingsModal from "@/components/panel/OfferSettingsModal";

interface ProductsPageContentProps {
  products: Array<{
    id: string;
    name: string;
    price: number;
    category: {
      id: string;
      name: string;
    };
    orderItems: Array<{ quantity: number }>;
    [key: string]: any;
  }>;
}

export default function ProductsPageContent({
  products,
}: ProductsPageContentProps) {
  const [isOfferModalOpen, setIsOfferModalOpen] = useState(false);

  return (
    <>
      <div className="space-y-6">
        <div>
          <h1 className="text-3xl font-bold text-gray-900">Produkty</h1>
          <p className="text-gray-600 mt-2">
            Zarządzaj produktami w swoim sklepie
          </p>
        </div>

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
          <button
            onClick={() => setIsOfferModalOpen(true)}
            className="flex items-center justify-center w-11 h-11 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors bg-white"
            title="Ustawienia oferty"
          >
            <Icon
              icon="material-symbols:shoppingmode"
              width="24"
              height="24"
              className="text-gray-600"
            />
          </button>
          <AddProductModal />
        </div>

        {/* Products Table */}
        <div className="bg-white rounded-2xl shadow-soft overflow-hidden">
          <InventoryTable products={products} />
        </div>
      </div>

      <OfferSettingsModal
        isOpen={isOfferModalOpen}
        onClose={() => setIsOfferModalOpen(false)}
      />
    </>
  );
}

