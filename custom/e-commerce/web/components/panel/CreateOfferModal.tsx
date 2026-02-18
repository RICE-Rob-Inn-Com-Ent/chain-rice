"use client";

import { useState } from "react";
import { Gift, X, Package, Sparkles } from "lucide-react";
import { useRouter } from "next/navigation";

interface Product {
  id: string;
  name: string;
  price: number;
  category: {
    name: string;
  };
}

interface CreateOfferModalProps {
  products: Product[];
}

export default function CreateOfferModal({ products }: CreateOfferModalProps) {
  const router = useRouter();
  const [isOpen, setIsOpen] = useState(false);
  const [offerType, setOfferType] = useState<"bundle" | "special">("bundle");
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    price: "",
    selectedProducts: [] as string[],
    isSpecialOffer: false,
    specialOfferType: "holiday" as "holiday" | "seasonal" | "limited",
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setIsSubmitting(true);

    try {
      const offerData = {
        name: formData.name,
        description: formData.description,
        price: parseFloat(formData.price),
        isBundle: offerType === "bundle",
        specialOffer: offerType === "special",
        productIds: formData.selectedProducts,
        specialOfferType: formData.specialOfferType,
      };

      const response = await fetch("/api/products/offer", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(offerData),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || "Błąd podczas tworzenia oferty");
      }

      router.refresh();
      setIsOpen(false);
      resetForm();
    } catch (err) {
      setError(err instanceof Error ? err.message : "Wystąpił błąd");
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetForm = () => {
    setFormData({
      name: "",
      description: "",
      price: "",
      selectedProducts: [],
      isSpecialOffer: false,
      specialOfferType: "holiday",
    });
    setOfferType("bundle");
  };

  const toggleProduct = (productId: string) => {
    setFormData((prev) => ({
      ...prev,
      selectedProducts: prev.selectedProducts.includes(productId)
        ? prev.selectedProducts.filter((id) => id !== productId)
        : [...prev.selectedProducts, productId],
    }));
  };

  const calculateBundlePrice = () => {
    const selected = products.filter((p) =>
      formData.selectedProducts.includes(p.id)
    );
    const total = selected.reduce((sum, p) => sum + Number(p.price), 0);
    return total.toFixed(2);
  };

  return (
    <>
      <button
        onClick={() => setIsOpen(true)}
        className="flex items-center gap-2 px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors font-medium"
      >
        <Gift className="w-5 h-5" />
        Stwórz ofertę
      </button>

      {isOpen && (
        <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
          <div className="bg-white rounded-2xl shadow-2xl w-full max-w-3xl max-h-[90vh] overflow-y-auto">
            {/* Header */}
            <div className="flex items-center justify-between p-6 border-b border-gray-200">
              <h2 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
                <Gift className="w-6 h-6 text-red-600" />
                Stwórz ofertę
              </h2>
              <button
                onClick={() => {
                  setIsOpen(false);
                  resetForm();
                }}
                className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <X className="w-5 h-5 text-gray-600" />
              </button>
            </div>

            {/* Form */}
            <form onSubmit={handleSubmit} className="p-6 space-y-6">
              {error && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
                  {error}
                </div>
              )}

              {/* Offer Type Selection */}
              <div className="space-y-3">
                <label className="block text-sm font-medium text-gray-700">
                  Typ oferty
                </label>
                <div className="grid grid-cols-2 gap-4">
                  <button
                    type="button"
                    onClick={() => setOfferType("bundle")}
                    className={`p-4 border-2 rounded-lg transition-all ${
                      offerType === "bundle"
                        ? "border-blue-600 bg-blue-50"
                        : "border-gray-200 hover:border-gray-300"
                    }`}
                  >
                    <Package className="w-6 h-6 mx-auto mb-2 text-blue-600" />
                    <div className="font-medium">Zestaw produktów</div>
                    <div className="text-sm text-gray-600 mt-1">
                      Wybierz produkty do zestawu
                    </div>
                  </button>
                  <button
                    type="button"
                    onClick={() => setOfferType("special")}
                    className={`p-4 border-2 rounded-lg transition-all ${
                      offerType === "special"
                        ? "border-red-600 bg-red-50"
                        : "border-gray-200 hover:border-gray-300"
                    }`}
                  >
                    <Sparkles className="w-6 h-6 mx-auto mb-2 text-red-600" />
                    <div className="font-medium">Okazja specjalna</div>
                    <div className="text-sm text-gray-600 mt-1">
                      Świąteczna mieszanka, sezonowa oferta
                    </div>
                  </button>
                </div>
              </div>

              {/* Basic Fields */}
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Nazwa oferty *
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) =>
                      setFormData({ ...formData, name: e.target.value })
                    }
                    placeholder={
                      offerType === "bundle"
                        ? "np. Zestaw kawowy Premium"
                        : "np. Świąteczna mieszanka 2024"
                    }
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Cena *
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    required
                    value={formData.price}
                    onChange={(e) =>
                      setFormData({ ...formData, price: e.target.value })
                    }
                    placeholder={offerType === "bundle" ? calculateBundlePrice() : "0.00"}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  {offerType === "bundle" && formData.selectedProducts.length > 0 && (
                    <p className="text-xs text-gray-500 mt-1">
                      Suma wybranych: {calculateBundlePrice()} zł
                    </p>
                  )}
                </div>
              </div>

              {/* Special Offer Type (only for special offers) */}
              {offerType === "special" && (
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Typ okazji
                  </label>
                  <select
                    value={formData.specialOfferType}
                    onChange={(e) =>
                      setFormData({
                        ...formData,
                        specialOfferType: e.target.value as any,
                      })
                    }
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="holiday">Świąteczna</option>
                    <option value="seasonal">Sezonowa</option>
                    <option value="limited">Limitowana</option>
                  </select>
                </div>
              )}

              {/* Description */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Opis
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) =>
                    setFormData({ ...formData, description: e.target.value })
                  }
                  rows={3}
                  placeholder="Opisz ofertę..."
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              {/* Product Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  {offerType === "bundle"
                    ? "Wybierz produkty do zestawu *"
                    : "Wybierz produkty w ofercie *"}
                </label>
                <div className="border border-gray-300 rounded-lg p-4 max-h-64 overflow-y-auto">
                  {products.length === 0 ? (
                    <p className="text-gray-500 text-center py-4">
                      Brak dostępnych produktów
                    </p>
                  ) : (
                    <div className="space-y-2">
                      {products.map((product) => (
                        <label
                          key={product.id}
                          className="flex items-center gap-3 p-2 hover:bg-gray-50 rounded cursor-pointer"
                        >
                          <input
                            type="checkbox"
                            checked={formData.selectedProducts.includes(
                              product.id
                            )}
                            onChange={() => toggleProduct(product.id)}
                            className="w-4 h-4 text-blue-600 border-gray-300 rounded focus:ring-blue-500"
                          />
                          <div className="flex-1">
                            <div className="font-medium text-gray-900">
                              {product.name}
                            </div>
                            <div className="text-sm text-gray-500">
                              {product.category.name} •{" "}
                              {Number(product.price).toLocaleString("pl-PL")} zł
                            </div>
                          </div>
                        </label>
                      ))}
                    </div>
                  )}
                </div>
                {formData.selectedProducts.length > 0 && (
                  <p className="text-sm text-gray-600 mt-2">
                    Wybrano: {formData.selectedProducts.length} produktów
                  </p>
                )}
              </div>

              {/* Submit Button */}
              <div className="flex justify-end gap-3 pt-4 border-t border-gray-200">
                <button
                  type="button"
                  onClick={() => {
                    setIsOpen(false);
                    resetForm();
                  }}
                  className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Anuluj
                </button>
                <button
                  type="submit"
                  disabled={
                    isSubmitting ||
                    !formData.name ||
                    !formData.price ||
                    formData.selectedProducts.length === 0
                  }
                  className="px-6 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
                >
                  {isSubmitting ? "Tworzenie..." : "Utwórz ofertę"}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}



