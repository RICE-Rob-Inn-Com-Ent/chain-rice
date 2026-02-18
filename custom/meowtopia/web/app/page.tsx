"use client";

import Link from "next/link";
import { Icon } from "@iconify/react";
import { useCartStore } from "@/lib/store/cart";
import { useEffect, useState } from "react";
import ProductCard from "../components/ui/ProductCard";

interface Product {
  id: string;
  name: string;
  price: number;
  category: string; // Tymczasowo dla kompatybilności
  categoryId: string;
  categoryName: string;
  categorySlug: string;
  images: string[];
  featured?: boolean;
  specialOffer?: boolean;
  isBundle?: boolean;
  description?: string;
  details?: {
    weight?: string;
  };
}

interface Category {
  id: string;
  name: string;
  slug: string;
  description?: string;
  icon?: string;
  active: boolean;
  order: number;
}

export default function HomePage() {
  const cartItemsCount = useCartStore((state) => state.getTotalItems());
  const [mounted, setMounted] = useState(false);
  const [products, setProducts] = useState<Product[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedCategoryId, setSelectedCategoryId] = useState<string | null>(null);

  useEffect(() => {
    setMounted(true);
    fetchData();
  }, []);

  const fetchData = async () => {
    try {
      // Pobierz kategorie i produkty równolegle
      const [categoriesResponse, productsResponse] = await Promise.all([
        fetch("/api/categories"),
        fetch("/api/products"),
      ]);

      if (categoriesResponse.ok) {
        const categoriesData = await categoriesResponse.json();
        setCategories(categoriesData);
      }

      if (productsResponse.ok) {
        const productsData = await productsResponse.json();
        setProducts(productsData);
      }
    } catch (error) {
      console.error("Error fetching data:", error);
    } finally {
      setLoading(false);
    }
  };

  // Podziel produkty na sekcje
  const specialOfferProducts = products.filter((p) => p.specialOffer === true);
  const bundleProducts = products.filter((p) => p.isBundle === true);
  const singleProducts = products.filter((p) => p.isBundle !== true && p.specialOffer !== true);

  return (
    <div className="min-h-screen">

      {/* Sekcja 1: Oferta Specjalna */}
      {specialOfferProducts.length > 0 && (
        <section id="oferta-specjalna" className="py-20 px-4 scroll-mt-24">
          <div className="max-w-7xl mx-auto">
            <div className="text-center mb-12">
              <h2 className="text-4xl md:text-5xl font-display font-bold text-meo-brown-800 mb-2">Okazja</h2>
              <div className="h-1 w-24 rounded-full bg-gradient-to-r from-[#F97316] to-[#A3D9A5] mx-auto" />
            </div>
            <div className="grid grid-cols-2 gap-4 max-w-2xl mx-auto">
              {specialOfferProducts.map((product) => (
                <div key={product.id} className="group">
                  <ProductCard product={product} />
                </div>
              ))}
            </div>
          </div>
        </section>
      )}

      {/* Sekcja 2: Zestawy - zawsze widoczne */}
      <section id="zestawy" className="py-20 px-4 scroll-mt-24">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-4xl md:text-5xl font-display font-bold text-meo-brown-800 mb-2">Zestawy Prezentowe</h2>
            <div className="h-1 w-24 rounded-full bg-gradient-to-r from-[#F97316] to-[#A3D9A5] mx-auto" />
          </div>
          {loading ? (
            <div className="text-center py-12">
              <p className="text-meo-brown-600">Ładowanie produktów...</p>
            </div>
          ) : bundleProducts.length > 0 ? (
            <div className="grid grid-cols-2 gap-4 max-w-2xl mx-auto">
              {bundleProducts.map((product) => (
                <div key={product.id} className="group">
                  <ProductCard product={product} />
                </div>
              ))}
            </div>
          ) : (
            <div className="text-center py-12">
              <div className="text-8xl mb-6">🎁</div>
              <p className="text-lg text-meo-brown-600">Brak zestawów</p>
            </div>
          )}
        </div>
      </section>

      {/* Sekcja 3: Pojedyncze Produkty */}
      <section id="produkty" className="py-20 px-4 scroll-mt-24">
        <div className="max-w-7xl mx-auto">
          <div className="text-center mb-12">
            <h2 className="text-4xl md:text-5xl font-display font-bold text-meo-brown-800 mb-2">Nasze Produkty</h2>
            <div className="h-1 w-24 rounded-full bg-gradient-to-r from-[#F97316] to-[#A3D9A5] mx-auto" />
          </div>

          {/* Filtry kategorii */}
          <div className="mb-8 flex flex-wrap justify-center gap-3">
            {categories.map((category) => (
              <button
                key={category.id}
                onClick={() => setSelectedCategoryId(selectedCategoryId === category.id ? null : category.id)}
                className={`px-6 py-3 rounded-full font-semibold transition-all flex items-center gap-2 ${
                  selectedCategoryId === category.id
                    ? "bg-[#F97316] text-white shadow-lg"
                    : "bg-white text-meo-brown-800 border-2 border-[#F97316] hover:bg-[#F97316]/10"
                }`}
              >
                {category.icon && <span className="text-xl">{category.icon}</span>}
                {category.name}
              </button>
            ))}
          </div>

          {/* Produkty */}
          <div className="mb-12">
            {loading ? (
              <div className="text-center py-12">
                <p className="text-meo-brown-600">Ładowanie produktów...</p>
              </div>
            ) : (selectedCategoryId === null
                ? singleProducts
                : singleProducts.filter((p) => p.categoryId === selectedCategoryId)
              ).length > 0 ? (
              <div className="grid grid-cols-2 gap-4 max-w-2xl mx-auto">
                {(selectedCategoryId === null
                  ? singleProducts
                  : singleProducts.filter((p) => p.categoryId === selectedCategoryId)
                ).map((product) => (
                  <div key={product.id} className="group">
                    <ProductCard product={product} />
                  </div>
                ))}
              </div>
            ) : (
              <div className="text-center py-12">
                <div className="text-8xl mb-6">😸</div>
                <h3 className="text-3xl font-bold text-meo-brown-800 mb-4">Brak produktów</h3>
                <p className="text-lg text-meo-brown-600">
                  Ale to dobrze - wszystko się wyprzedało! Oczekujcie niedługo nowych produktów.
                </p>
              </div>
            )}
          </div>
        </div>
      </section>

      {/* Fixed Cart Summary */}
      <Link
        href="/shopping-bag"
        className="fixed bottom-6 right-6 z-50 bg-[#F97316] text-white w-14 h-14 rounded-full shadow-xl flex items-center justify-center hover:bg-orange-500 transition-all hover:scale-105 focus:outline-none focus:ring-4 focus:ring-orange-200"
        aria-label={`Koszyk ${mounted && cartItemsCount > 0 ? `(${cartItemsCount})` : ""}`}
      >
        <Icon icon="material-symbols:shopping-bag" className="w-6 h-6 rounded" />
        {mounted && cartItemsCount > 0 && (
          <span className="absolute -top-1 -right-1 bg-red-500 text-white text-xs rounded-full w-5 h-5 flex items-center justify-center font-bold shadow-md">
            {cartItemsCount > 9 ? "9+" : cartItemsCount}
          </span>
        )}
      </Link>

      <style jsx>{`
        @keyframes fadeInSmooth {
          from {
            opacity: 0;
            transform: translateY(15px);
          }
          to {
            opacity: 1;
            transform: translateY(0);
          }
        }

        .animate-fadeInSmooth {
          animation: fadeInSmooth 1s ease-out forwards;
          opacity: 0;
        }
      `}</style>
    </div>
  );
}
