"use client";

import { useEffect, useState } from "react";
import { Icon } from "@iconify/react";
import { X, Package, Sparkles, Settings, Gift } from "lucide-react";
import { useRouter } from "next/navigation";

interface StoreSettingsResponse {
  freeShippingThreshold: number;
}

interface Product {
  id: string;
  name: string;
  price: number;
  category: {
    name: string;
  };
}

interface OfferSettingsModalProps {
  isOpen: boolean;
  onClose: () => void;
}

type TabType = "settings" | "bundles" | "special";

export default function OfferSettingsModal({
  isOpen,
  onClose,
}: OfferSettingsModalProps) {
  const router = useRouter();
  const [activeTab, setActiveTab] = useState<TabType>("settings");
  
  // Settings tab
  const [freeShippingThreshold, setFreeShippingThreshold] = useState<number>(199);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);
  
  // Bundles & Special Offers tabs
  const [products, setProducts] = useState<Product[]>([]);
  const [loadingProducts, setLoadingProducts] = useState(false);
  const [offerType, setOfferType] = useState<"bundle" | "special">("bundle");
  const [formData, setFormData] = useState({
    name: "",
    description: "",
    price: "",
    selectedProducts: [] as string[],
    specialOfferType: "holiday" as string,
    customOfferType: "",
    images: [] as File[],
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [offerError, setOfferError] = useState<string | null>(null);
  const [imagePreviewUrls, setImagePreviewUrls] = useState<string[]>([]);

  useEffect(() => {
    if (isOpen) {
      fetchSettings();
      if (activeTab === "bundles" || activeTab === "special") {
        fetchProducts();
      }
    }
  }, [isOpen, activeTab]);

  const fetchSettings = async () => {
    setLoading(true);
    setError(null);
    try {
      const res = await fetch("/api/store-settings");
      if (res.ok) {
        const data = (await res.json()) as StoreSettingsResponse;
        if (typeof data.freeShippingThreshold === "number") {
          setFreeShippingThreshold(data.freeShippingThreshold);
        }
      }
    } catch (e) {
      console.error("Error loading store settings", e);
      setError("Nie udało się załadować ustawień sklepu.");
    } finally {
      setLoading(false);
    }
  };

  const fetchProducts = async () => {
    setLoadingProducts(true);
    try {
      const res = await fetch("/api/products");
      if (res.ok) {
        const data = await res.json();
        // Filtruj tylko produkty, które nie są już zestawami ani ofertami specjalnymi
        const regularProducts = data.filter(
          (p: any) => !p.isBundle && !p.specialOffer
        );
        setProducts(
          regularProducts.map((p: any) => ({
            id: p.id,
            name: p.name,
            price: p.price,
            category: {
              name: p.categoryName || p.category?.name || "Brak kategorii",
            },
          }))
        );
      }
    } catch (e) {
      console.error("Error loading products", e);
      setOfferError("Nie udało się załadować produktów.");
    } finally {
      setLoadingProducts(false);
    }
  };

  const handleSettingsSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setSaving(true);
    setError(null);
    setSuccess(null);

    try {
      const res = await fetch("/api/store-settings", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({ freeShippingThreshold }),
      });

      if (!res.ok) {
        const data = await res.json().catch(() => ({}));
        throw new Error(data.error || "Błąd zapisu ustawień");
      }

      setSuccess("Ustawienia zostały zapisane.");
      setTimeout(() => {
        setSuccess(null);
      }, 2000);
    } catch (e: any) {
      setError(e.message || "Nie udało się zapisać ustawień.");
    } finally {
      setSaving(false);
    }
  };

  const handleOfferSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setOfferError(null);
    setIsSubmitting(true);

    try {
      // Upload images if any
      let imageUrls: string[] = [];
      if (formData.images.length > 0 && formData.name) {
        const uploadImages = async (images: File[], productName: string, categoryType: string): Promise<string[]> => {
          if (!images || images.length === 0) return [];

          const formDataUpload = new FormData();
          images.forEach((file) => {
            formDataUpload.append('files', file);
          });
          formDataUpload.append('category', categoryType);
          formDataUpload.append('productName', productName);

          const uploadResponse = await fetch('/api/upload', {
            method: 'POST',
            body: formDataUpload,
          });

          if (!uploadResponse.ok) {
            const errorData = await uploadResponse.json();
            throw new Error(errorData.error || 'Failed to upload images');
          }

          const result = await uploadResponse.json();
          const urls = result.urls || [];
          
          if (urls.length === 0 && images.length > 0) {
            throw new Error('Przesyłanie zakończone, ale nie otrzymano adresów URL zdjęć');
          }
          
          return urls;
        };

        const categoryType = activeTab === "bundles" ? "zestaw" : "oferta-specjalna";
        imageUrls = await uploadImages(formData.images, formData.name, categoryType);
      }

      const offerData = {
        name: formData.name,
        description: formData.description,
        price: parseFloat(formData.price),
        isBundle: activeTab === "bundles",
        specialOffer: activeTab === "special",
        productIds: formData.selectedProducts,
        specialOfferType:
          activeTab === "special"
            ? formData.customOfferType || formData.specialOfferType
            : undefined,
        images: imageUrls,
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
      resetOfferForm();
      setSuccess(
        activeTab === "bundles"
          ? "Zestaw został utworzony!"
          : "Oferta specjalna została utworzona!"
      );
      setTimeout(() => {
        setSuccess(null);
      }, 2000);
    } catch (err) {
      setOfferError(err instanceof Error ? err.message : "Wystąpił błąd");
    } finally {
      setIsSubmitting(false);
    }
  };

  const resetOfferForm = () => {
    // Clean up image preview URLs
    imagePreviewUrls.forEach(url => URL.revokeObjectURL(url));
    
    setFormData({
      name: "",
      description: "",
      price: "",
      selectedProducts: [],
      specialOfferType: "holiday",
      customOfferType: "",
      images: [],
    });
    setImagePreviewUrls([]);
    setOfferError(null);
  };

  const handleImageChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const files = Array.from(e.target.files || []);
    if (files.length === 0) return;

    // Clean up old preview URLs
    imagePreviewUrls.forEach(url => URL.revokeObjectURL(url));

    // Create preview URLs
    const newPreviewUrls = files.map(file => URL.createObjectURL(file));
    setImagePreviewUrls(newPreviewUrls);

    setFormData(prev => ({
      ...prev,
      images: [...prev.images, ...files],
    }));
  };

  const removeImage = (index: number) => {
    const newImages = [...formData.images];
    const removedUrl = imagePreviewUrls[index];
    URL.revokeObjectURL(removedUrl);
    
    newImages.splice(index, 1);
    const newPreviewUrls = [...imagePreviewUrls];
    newPreviewUrls.splice(index, 1);
    
    setFormData(prev => ({ ...prev, images: newImages }));
    setImagePreviewUrls(newPreviewUrls);
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

  if (!isOpen) return null;

  const tabs = [
    {
      id: "settings" as TabType,
      label: "Ustawienia",
      icon: Settings,
    },
    {
      id: "bundles" as TabType,
      label: "Zestawy",
      icon: Package,
    },
    {
      id: "special" as TabType,
      label: "Oferty specjalne",
      icon: Sparkles,
    },
  ];

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-hidden flex flex-col">
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-gray-200">
          <h2 className="text-2xl font-bold text-gray-900 flex items-center gap-2">
            <Icon
              icon="material-symbols:shoppingmode"
              width="24"
              height="24"
              className="text-blue-600"
            />
            Ustawienia oferty
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
          >
            <X className="w-5 h-5 text-gray-600" />
          </button>
        </div>

        {/* Tabs */}
        <div className="border-b border-gray-200 px-6">
          <div className="flex gap-2">
            {tabs.map((tab) => {
              const IconComponent = tab.icon;
              return (
                <button
                  key={tab.id}
                  onClick={() => {
                    setActiveTab(tab.id);
                    setError(null);
                    setOfferError(null);
                    setSuccess(null);
                  }}
                  className={`flex items-center gap-2 px-4 py-3 border-b-2 transition-colors ${
                    activeTab === tab.id
                      ? "border-blue-600 text-blue-600 font-semibold"
                      : "border-transparent text-gray-600 hover:text-gray-900"
                  }`}
                >
                  <IconComponent className="w-5 h-5" />
                  {tab.label}
                </button>
              );
            })}
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 overflow-y-auto p-6">
          {/* Settings Tab */}
          {activeTab === "settings" && (
            <div>
              <h3 className="text-xl font-semibold text-gray-900 mb-4">
                Darmowa dostawa
              </h3>

              {loading ? (
                <p className="text-gray-500 text-sm">Ładowanie ustawień...</p>
              ) : (
                <form onSubmit={handleSettingsSubmit} className="space-y-4">
                  <div>
                    <label
                      htmlFor="freeShippingThreshold"
                      className="block text-sm font-medium text-gray-700 mb-1"
                    >
                      Próg darmowej dostawy (zł)
                    </label>
                    <input
                      id="freeShippingThreshold"
                      type="number"
                      step="1"
                      min="0"
                      value={
                        Number.isNaN(freeShippingThreshold)
                          ? ""
                          : freeShippingThreshold
                      }
                      onChange={(e) =>
                        setFreeShippingThreshold(Number(e.target.value))
                      }
                      className="block w-full px-4 py-2 rounded-md border-gray-300 focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                    />
                    <p className="mt-1 text-xs text-gray-500">
                      Powyżej tej kwoty wartość dostawy w koszyku będzie
                      wynosić 0 zł (z wyjątkiem odbioru osobistego, który i tak
                      jest darmowy).
                    </p>
                  </div>

                  {error && (
                    <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg text-sm">
                      {error}
                    </div>
                  )}
                  {success && (
                    <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg text-sm">
                      {success}
                    </div>
                  )}

                  <div className="flex justify-end gap-3 pt-4">
                    <button
                      type="submit"
                      disabled={saving}
                      className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
                    >
                      {saving ? "Zapisywanie..." : "Zapisz ustawienia"}
                    </button>
                  </div>
                </form>
              )}
            </div>
          )}

          {/* Bundles Tab */}
          {activeTab === "bundles" && (
            <form onSubmit={handleOfferSubmit} className="space-y-6">
              {offerError && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
                  {offerError}
                </div>
              )}
              {success && (
                <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg">
                  {success}
                </div>
              )}

              <div>
                <h3 className="text-xl font-semibold text-gray-900 mb-4">
                  Stwórz zestaw prezentowy
                </h3>
                <p className="text-sm text-gray-600 mb-4">
                  Wybierz produkty, które mają być w zestawie. Cena zestawu może
                  być niższa niż suma cen pojedynczych produktów.
                </p>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Nazwa zestawu *
                  </label>
                  <input
                    type="text"
                    required
                    value={formData.name}
                    onChange={(e) =>
                      setFormData({ ...formData, name: e.target.value })
                    }
                    placeholder="np. Zestaw kawowy Premium"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Cena zestawu *
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    required
                    value={formData.price}
                    onChange={(e) =>
                      setFormData({ ...formData, price: e.target.value })
                    }
                    placeholder={calculateBundlePrice()}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                  {formData.selectedProducts.length > 0 && (
                    <p className="text-xs text-gray-500 mt-1">
                      Suma wybranych: {calculateBundlePrice()} zł
                    </p>
                  )}
                </div>
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Opis zestawu
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) =>
                    setFormData({ ...formData, description: e.target.value })
                  }
                  rows={3}
                  placeholder="Opisz zestaw..."
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Zdjęcia zestawu
                </label>
                <input
                  type="file"
                  accept="image/*"
                  multiple
                  onChange={handleImageChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                {imagePreviewUrls.length > 0 && (
                  <div className="mt-4 grid grid-cols-4 gap-4">
                    {imagePreviewUrls.map((url, index) => (
                      <div key={index} className="relative">
                        <img
                          src={url}
                          alt={`Preview ${index + 1}`}
                          className="w-full h-24 object-cover rounded-lg"
                        />
                        <button
                          type="button"
                          onClick={() => removeImage(index)}
                          className="absolute top-1 right-1 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs hover:bg-red-600"
                        >
                          ×
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Wybierz produkty do zestawu *
                </label>
                {loadingProducts ? (
                  <p className="text-gray-500 text-sm">Ładowanie produktów...</p>
                ) : (
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
                )}
                {formData.selectedProducts.length > 0 && (
                  <p className="text-sm text-gray-600 mt-2">
                    Wybrano: {formData.selectedProducts.length} produktów
                  </p>
                )}
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-gray-200">
                <button
                  type="button"
                  onClick={() => {
                    resetOfferForm();
                    setOfferError(null);
                  }}
                  className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Wyczyść
                </button>
                <button
                  type="submit"
                  disabled={
                    isSubmitting ||
                    !formData.name ||
                    !formData.price ||
                    formData.selectedProducts.length === 0
                  }
                  className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors disabled:opacity-50 disabled:cursor-not-allowed font-medium"
                >
                  {isSubmitting ? "Tworzenie..." : "Utwórz zestaw"}
                </button>
              </div>
            </form>
          )}

          {/* Special Offers Tab */}
          {activeTab === "special" && (
            <form onSubmit={handleOfferSubmit} className="space-y-6">
              {offerError && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
                  {offerError}
                </div>
              )}
              {success && (
                <div className="bg-green-50 border border-green-200 text-green-700 px-4 py-3 rounded-lg">
                  {success}
                </div>
              )}

              <div>
                <h3 className="text-xl font-semibold text-gray-900 mb-4">
                  Stwórz ofertę specjalną
                </h3>
                <p className="text-sm text-gray-600 mb-4">
                  Twórz unikalne oferty na święta, okazje lub inne specjalne
                  wydarzenia. Maksymalna elastyczność w konfiguracji.
                </p>
              </div>

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
                    placeholder="np. Świąteczna mieszanka 2024"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Cena oferty *
                  </label>
                  <input
                    type="number"
                    step="0.01"
                    required
                    value={formData.price}
                    onChange={(e) =>
                      setFormData({ ...formData, price: e.target.value })
                    }
                    placeholder="0.00"
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  />
                </div>
              </div>

              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Typ okazji
                  </label>
                  <select
                    value={
                      formData.specialOfferType === "custom" ||
                      formData.customOfferType !== ""
                        ? "custom"
                        : formData.specialOfferType
                    }
                    onChange={(e) => {
                      if (e.target.value === "custom") {
                        setFormData({
                          ...formData,
                          specialOfferType: "custom",
                          customOfferType: "",
                        });
                      } else {
                        setFormData({
                          ...formData,
                          specialOfferType: e.target.value,
                          customOfferType: "",
                        });
                      }
                    }}
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                  >
                    <option value="holiday">Świąteczna</option>
                    <option value="seasonal">Sezonowa</option>
                    <option value="limited">Limitowana</option>
                    <option value="anniversary">Rocznica</option>
                    <option value="birthday">Urodzinowa</option>
                    <option value="valentine">Walentynkowa</option>
                    <option value="easter">Wielkanocna</option>
                    <option value="custom">Własna (wpisz poniżej)</option>
                  </select>
                </div>
                {(formData.specialOfferType === "custom" ||
                  formData.customOfferType !== "") && (
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Własny typ okazji
                    </label>
                    <input
                      type="text"
                      value={formData.customOfferType}
                      onChange={(e) =>
                        setFormData({
                          ...formData,
                          customOfferType: e.target.value,
                        })
                      }
                      placeholder="np. Black Friday, Dzień Matki..."
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Opis oferty
                </label>
                <textarea
                  value={formData.description}
                  onChange={(e) =>
                    setFormData({ ...formData, description: e.target.value })
                  }
                  rows={4}
                  placeholder="Opisz ofertę specjalną, jej charakter, okazję..."
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Zdjęcia oferty
                </label>
                <input
                  type="file"
                  accept="image/*"
                  multiple
                  onChange={handleImageChange}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                {imagePreviewUrls.length > 0 && (
                  <div className="mt-4 grid grid-cols-4 gap-4">
                    {imagePreviewUrls.map((url, index) => (
                      <div key={index} className="relative">
                        <img
                          src={url}
                          alt={`Preview ${index + 1}`}
                          className="w-full h-24 object-cover rounded-lg"
                        />
                        <button
                          type="button"
                          onClick={() => removeImage(index)}
                          className="absolute top-1 right-1 bg-red-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-xs hover:bg-red-600"
                        >
                          ×
                        </button>
                      </div>
                    ))}
                  </div>
                )}
              </div>

              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Wybierz produkty w ofercie *
                </label>
                {loadingProducts ? (
                  <p className="text-gray-500 text-sm">Ładowanie produktów...</p>
                ) : (
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
                )}
                {formData.selectedProducts.length > 0 && (
                  <p className="text-sm text-gray-600 mt-2">
                    Wybrano: {formData.selectedProducts.length} produktów
                  </p>
                )}
              </div>

              <div className="flex justify-end gap-3 pt-4 border-t border-gray-200">
                <button
                  type="button"
                  onClick={() => {
                    resetOfferForm();
                    setOfferError(null);
                  }}
                  className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Wyczyść
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
                  {isSubmitting ? "Tworzenie..." : "Utwórz ofertę specjalną"}
                </button>
              </div>
            </form>
          )}
        </div>

        {/* Footer */}
        <div className="border-t border-gray-200 p-4 flex justify-end">
          <button
            onClick={onClose}
            className="px-4 py-2 text-gray-700 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
          >
            Zamknij
          </button>
        </div>
      </div>
    </div>
  );
}

