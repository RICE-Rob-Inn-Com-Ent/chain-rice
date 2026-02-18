"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
// Prisma types - will be available after running: yarn prisma generate
// @ts-ignore - Prisma types not generated yet
import type { Product } from "@prisma/client";
import { Edit2, Trash2, Eye, Package } from "lucide-react";
import Link from "next/link";
import Image from "next/image";
import EditProductModal from "./EditProductModal";

interface InventoryTableProps {
  products: (Product & {
    category: { id: string; name: string; slug: string } | null;
    orderItems: { quantity: number }[];
    bundleProducts?: Array<{
      id: string;
      productId: string;
      quantity: number;
      product: {
        id: string;
        name: string;
        stock: number;
        active: boolean;
      };
    }>;
  })[];
}

export default function InventoryTable({ products }: InventoryTableProps) {
  const router = useRouter();
  const [deletingId, setDeletingId] = useState<string | null>(null);
  const [editingProduct, setEditingProduct] = useState<(Product & {
    category: { id: string; name: string; slug: string } | null;
    orderItems: { quantity: number }[];
  }) | null>(null);

  const handleDelete = async (productId: string, productName: string) => {
    if (!confirm(`Czy na pewno chcesz usunąć produkt "${productName}"?`)) {
      return;
    }

    setDeletingId(productId);
    try {
      const response = await fetch(`/api/products/${productId}`, {
        method: 'DELETE',
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to delete product');
      }

      // Odśwież stronę aby pokazać zaktualizowaną listę
      router.refresh();
    } catch (error) {
      console.error('Error deleting product:', error);
      alert(error instanceof Error ? error.message : 'Nie udało się usunąć produktu');
    } finally {
      setDeletingId(null);
    }
  };

  const getCategoryLabel = (category: any) => {
    if (typeof category === "object" && category?.name) {
      return category.name;
    }
    const labels: Record<string, string> = {
      COFFEE: "Kawa",
      TEA: "Herbata",
      ILLUSTRATION: "Ilustracja",
      "dzieła-artystów": "Dzieła artystów",
      kawa: "Kawa",
      herbata: "Herbata",
    };
    return labels[category] || category || "Inna";
  };

  const getCategorySpecificInfo = (product: Product & { 
    orderItems: { quantity: number }[];
    bundleProducts?: Array<{
      id: string;
      productId: string;
      quantity: number;
      product: {
        id: string;
        name: string;
        stock: number;
        active: boolean;
      };
    }>;
  }) => {
    // For bundles, show list of component products
    if (product.isBundle && product.bundleProducts && product.bundleProducts.length > 0) {
      const componentNames = product.bundleProducts.map(bp => bp.product.name).join(", ");
      return {
        label: "Składa się z",
        value: componentNames || "—",
      };
    }

    const categoryName = typeof product.category === "object" 
      ? product.category?.name?.toLowerCase() 
      : product.category?.toLowerCase() || "";

    if (categoryName.includes("kawa") || categoryName === "coffee") {
      return {
        label: "Profil palenia",
        value: (product as any).roastProfile || "—",
      };
    }
    if (categoryName.includes("herbata") || categoryName === "tea") {
      return {
        label: "Temperatura",
        value: (product as any).brewingTemperature 
          ? `${(product as any).brewingTemperature}°C` 
          : "—",
      };
    }
    if (categoryName.includes("dzieła") || categoryName.includes("artyst")) {
      return {
        label: "Typ",
        value: (product as any).artworkType || "—",
      };
    }
    return null;
  };

  const calculateBundleStock = (product: Product & {
    bundleProducts?: Array<{
      id: string;
      productId: string;
      quantity: number;
      product: {
        id: string;
        name: string;
        stock: number;
        active: boolean;
      };
    }>;
  }): number => {
    if (!product.isBundle || !product.bundleProducts || product.bundleProducts.length === 0) {
      return product.stock;
    }

    // Calculate available bundles based on component products
    const availableBundles = product.bundleProducts.map((bp) => {
      if (!bp.product.active || bp.product.stock <= 0) {
        return 0;
      }
      return Math.floor(bp.product.stock / bp.quantity);
    });

    return Math.min(...availableBundles);
  };

  const getTotalSold = (product: Product & { orderItems: { quantity: number }[] }) => {
    return product.orderItems.reduce((sum, item) => sum + item.quantity, 0);
  };

  return (
    <div className="overflow-x-auto">
      <table className="w-full">
        <thead className="bg-meo-beige-100">
          <tr>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Produkt
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Kategoria
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Cena
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Stan
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Sprzedano
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Szczegóły
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Status
            </th>
            <th className="text-left p-4 text-sm font-semibold text-meo-brown-800">
              Akcje
            </th>
          </tr>
        </thead>
        <tbody>
          {products.map((product) => {
            const totalSold = getTotalSold(product);
            return (
              <tr
                key={product.id}
                className="border-b border-meo-beige-200 hover:bg-meo-beige-50"
              >
                <td className="p-4">
                  <div className="flex items-center gap-3">
                    <div className="w-16 h-16 bg-meo-beige-200 rounded-lg flex items-center justify-center overflow-hidden relative flex-shrink-0">
                      {(() => {
                        const imageUrl = product.images && product.images.length > 0 ? product.images[0] : null;
                        if (imageUrl) {
                          console.log(`[InventoryTable] Rendering image for "${product.name}":`, imageUrl);
                          return (
                            <img
                              src={imageUrl}
                              alt={product.name}
                              className="w-full h-full object-cover"
                              onError={(e) => {
                                console.error(`[InventoryTable] Failed to load image for "${product.name}":`, imageUrl);
                                // Fallback do ikony jeśli zdjęcie się nie załaduje
                                (e.target as HTMLImageElement).style.display = 'none';
                                const parent = (e.target as HTMLImageElement).parentElement;
                                if (parent && !parent.querySelector('.fallback-icon')) {
                                  const icon = document.createElement('div');
                                  icon.className = 'fallback-icon';
                                  icon.innerHTML = '<svg class="w-5 h-5 text-meo-brown-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 7l-8-4-8 4m16 0l-8 4m8-4v10l-8 4m0-10L4 7m8 4v10M4 7v10l8 4"></path></svg>';
                                  parent.appendChild(icon);
                                }
                              }}
                              onLoad={() => {
                                console.log(`[InventoryTable] Successfully loaded image for "${product.name}":`, imageUrl);
                              }}
                            />
                          );
                        } else {
                          console.log(`[InventoryTable] No images for "${product.name}". Images array:`, product.images);
                          return <Package className="w-5 h-5 text-meo-brown-600" />;
                        }
                      })()}
                    </div>
                    <div>
                      <div className="font-medium text-meo-brown-800">
                        {product.name}
                      </div>
                      {product.featured && (
                        <span className="text-xs bg-meo-primary text-white px-2 py-0.5 rounded-full">
                          Polecane
                        </span>
                      )}
                    </div>
                  </div>
                </td>
                <td className="p-4">
                  <span className="px-3 py-1 bg-meo-nature/10 text-meo-nature rounded-full text-xs font-medium">
                    {product.isBundle 
                      ? "Zestaw"
                      : (product.category?.name || getCategoryLabel(
                          typeof product.category === "object"
                            ? product.category
                            : product.categoryId || product.category
                        ))
                    }
                  </span>
                </td>
                <td className="p-4 font-semibold text-meo-brown-800">
                  {Number(product.price).toLocaleString("pl-PL")} zł
                </td>
                <td className="p-4">
                  {(() => {
                    const displayStock = product.isBundle 
                      ? calculateBundleStock(product)
                      : product.stock;
                    return (
                      <span
                        className={`font-medium ${
                          displayStock > 10
                            ? "text-green-600"
                            : displayStock > 0
                            ? "text-yellow-600"
                            : "text-red-600"
                        }`}
                      >
                        {displayStock} szt.
                      </span>
                    );
                  })()}
                </td>
                <td className="p-4 text-meo-brown-700">{totalSold}</td>
                <td className="p-4">
                  {(() => {
                    const categoryInfo = getCategorySpecificInfo(product);
                    return categoryInfo ? (
                      <div className="text-sm">
                        <span className="text-gray-500">{categoryInfo.label}:</span>{" "}
                        <span className="font-medium text-meo-brown-800">
                          {categoryInfo.value}
                        </span>
                      </div>
                    ) : (
                      <span className="text-gray-400">—</span>
                    );
                  })()}
                </td>
                <td className="p-4">
                  <span
                    className={`px-3 py-1 rounded-full text-xs font-medium ${
                      product.active
                        ? "bg-green-100 text-green-800"
                        : "bg-red-100 text-red-800"
                    }`}
                  >
                    {product.active ? "Aktywny" : "Nieaktywny"}
                  </span>
                </td>
                <td className="p-4">
                  <div className="flex items-center gap-2">
                    <Link
                      href={`/product/${product.id}`}
                      className="p-2 text-meo-brown-600 hover:bg-meo-beige-100 rounded-lg transition-colors"
                      title="Podgląd"
                    >
                      <Eye className="w-4 h-4" />
                    </Link>
                    <button
                      onClick={() => setEditingProduct(product)}
                      className="p-2 text-meo-brown-600 hover:bg-meo-beige-100 rounded-lg transition-colors"
                      title="Edytuj"
                    >
                      <Edit2 className="w-4 h-4" />
                    </button>
                    <button
                      onClick={() => handleDelete(product.id, product.name)}
                      disabled={deletingId === product.id}
                      className="p-2 text-red-500 hover:bg-red-50 rounded-lg transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
                      title="Usuń"
                    >
                      <Trash2 className="w-4 h-4" />
                    </button>
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
      
      {editingProduct && (
        <EditProductModal
          product={editingProduct}
          isOpen={true}
          onClose={() => setEditingProduct(null)}
        />
      )}
    </div>
  );
}








