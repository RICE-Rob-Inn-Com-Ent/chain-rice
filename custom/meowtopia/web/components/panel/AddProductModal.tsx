"use client";

import { useState, useEffect, useMemo } from "react";
import { Plus, X } from "lucide-react";
import { useRouter } from "next/navigation";

type ProductCategory = "kawa" | "herbata" | "dzieła-artystów";

interface ArtistWork {
  type: "obraz" | "figurka" | "rękodzieło" | "inne";
  title: string;
  description?: string;
  imageUrl?: string;
  artistSocialLinks?: string[];
}

export default function AddProductModal() {
  const router = useRouter();
  const [isOpen, setIsOpen] = useState(false);
  const [category, setCategory] = useState<ProductCategory>("kawa");
  const [artistWorks, setArtistWorks] = useState<ArtistWork[]>([]);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  // Cache dla URL-i obrazów - używamy useRef aby uniknąć problemów z dependency arrays
  const imageUrlCacheRef = useMemo(() => new Map<File, string>(), []);

  // Tworzenie URL-i dla obrazów
  const getImageUrl = (file: File): string => {
    if (!imageUrlCacheRef.has(file)) {
      const url = URL.createObjectURL(file);
      imageUrlCacheRef.set(file, url);
      return url;
    }
    return imageUrlCacheRef.get(file)!;
  };

  // Czyszczenie URL-i przy unmount
  useEffect(() => {
    return () => {
      imageUrlCacheRef.forEach(url => URL.revokeObjectURL(url));
      imageUrlCacheRef.clear();
    };
  }, [imageUrlCacheRef]);

  // Kawa fields
  const [coffeeData, setCoffeeData] = useState({
    name: "",
    images: [] as File[],
    flavorProfile: "",
    price: "",
    vatTax: "",
    sku: "",
    quantity: "",
    expiryDate: "",
    originCountry: "",
    roastProfile: "",
    weight: "",
    description: "",
  });

  // Herbata fields
  const [teaData, setTeaData] = useState({
    name: "",
    images: [] as File[],
    weight: "",
    price: "",
    vatTax: "",
    quantity: "",
    brewingTemperature: "",
    brewingTime: "",
    flavorNotes: "",
    description: "",
    originCountry: "",
  });

  // Dzieła artystów fields
  const [artistWorkData, setArtistWorkData] = useState({
    type: "obraz" as "obraz" | "figurka" | "rękodzieło" | "inne",
    title: "",
    images: [] as File[],
    price: "",
    vatTax: "",
    weight: "",
    originCountry: "",
    description: "",
    artistName: "",
    artistSocialLinks: [] as string[],
  });

  const addArtistWork = () => {
    setArtistWorks([...artistWorks, { type: "obraz", title: "", artistSocialLinks: [] }]);
  };

  const removeArtistWork = (index: number) => {
    setArtistWorks(artistWorks.filter((_, i) => i !== index));
  };

  const updateArtistWork = (index: number, field: keyof ArtistWork, value: any) => {
    const updated = [...artistWorks];
    updated[index] = { ...updated[index], [field]: value };
    setArtistWorks(updated);
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      // Funkcja do uploadu zdjęć do S3 (z fallback do lokalnego)
      const uploadImages = async (images: File[], productName: string, categoryType: string): Promise<string[]> => {
        if (!images || images.length === 0) return [];

        const formData = new FormData();
        images.forEach((file) => {
          formData.append('files', file);
        });
        formData.append('category', categoryType);
        formData.append('productName', productName);

        const uploadResponse = await fetch('/api/upload', {
          method: 'POST',
          body: formData,
        });

        if (!uploadResponse.ok) {
          const errorData = await uploadResponse.json();
          throw new Error(errorData.error || 'Failed to upload images');
        }

        const result = await uploadResponse.json();
        const urls = result.urls || [];
        console.log('Upload API response:', { success: result.success, urlsCount: urls.length, urls });
        
        if (urls.length === 0) {
          console.error('Upload succeeded but no URLs returned');
          throw new Error('Przesyłanie zakończone, ale nie otrzymano adresów URL zdjęć');
        }
        
        return urls;
      };

      // Upload zdjęć dla odpowiedniej kategorii
      let imageUrls: string[] = [];
      if (category === 'kawa' && coffeeData.images.length > 0 && coffeeData.name) {
        console.log('Uploading images for kawa:', coffeeData.images.length, 'files');
        imageUrls = await uploadImages(coffeeData.images, coffeeData.name, 'kawa');
        console.log('Uploaded image URLs:', imageUrls);
      } else if (category === 'herbata' && teaData.images.length > 0 && teaData.name) {
        console.log('Uploading images for herbata:', teaData.images.length, 'files');
        imageUrls = await uploadImages(teaData.images, teaData.name, 'herbata');
        console.log('Uploaded image URLs:', imageUrls);
      } else if (category === 'dzieła-artystów' && artistWorkData.images.length > 0 && artistWorkData.title) {
        console.log('Uploading images for dzieła-artystów:', artistWorkData.images.length, 'files');
        imageUrls = await uploadImages(artistWorkData.images, artistWorkData.title, 'dzieła-artystów');
        console.log('Uploaded image URLs:', imageUrls);
      }
      
      if (imageUrls.length === 0 && (
        (category === 'kawa' && coffeeData.images.length > 0) ||
        (category === 'herbata' && teaData.images.length > 0) ||
        (category === 'dzieła-artystów' && artistWorkData.images.length > 0)
      )) {
        console.warn('Warning: Images were selected but upload returned no URLs');
        setError('Nie udało się przesłać zdjęć. Spróbuj ponownie.');
        setIsSubmitting(false);
        return;
      }

      // Przygotuj dane do wysłania z URL-ami zdjęć
      const prepareDataForSubmit = (data: any, uploadedUrls: string[]) => {
        if (!data) return null;
        const { images, ...rest } = data;
        return {
          ...rest,
          images: uploadedUrls.length > 0 ? uploadedUrls : undefined,
        };
      };

      const response = await fetch('/api/products', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          category,
          coffeeData: category === 'kawa' ? prepareDataForSubmit(coffeeData, imageUrls) : null,
          teaData: category === 'herbata' ? prepareDataForSubmit(teaData, imageUrls) : null,
          artistWorkData: category === 'dzieła-artystów' ? prepareDataForSubmit(artistWorkData, imageUrls) : null,
        }),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to create product');
      }

      // Reset form
      setCoffeeData({
        name: "",
        images: [],
        flavorProfile: "",
        price: "",
        vatTax: "",
        sku: "",
        quantity: "",
        expiryDate: "",
        originCountry: "",
        roastProfile: "",
        weight: "",
        description: "",
      });
      setTeaData({
        name: "",
        images: [],
        weight: "",
        price: "",
        vatTax: "",
        quantity: "",
        brewingTemperature: "",
        brewingTime: "",
        flavorNotes: "",
        description: "",
        originCountry: "",
      });
      setArtistWorkData({
        type: "obraz",
        title: "",
        images: [],
        price: "",
        vatTax: "",
        weight: "",
        originCountry: "",
        description: "",
        artistName: "",
        artistSocialLinks: [],
      });
      setArtistWorks([]);

      setIsOpen(false);
      
      // Refresh the page to show the new product
      router.refresh();
    } catch (err) {
      console.error('Error creating product:', err);
      setError(err instanceof Error ? err.message : 'Failed to create product');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <>
      <button
        onClick={() => setIsOpen(true)}
        className="flex items-center justify-center w-11 h-11 bg-[#B4C588] text-black rounded-lg hover:bg-[#A3D9A5] transition-colors shadow-sm"
      >
        <Plus className="w-5 h-5" />
      </button>

      {isOpen && (
        <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
            <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
              <h2 className="text-2xl font-bold text-gray-900">Dodaj produkt</h2>
              <button
                onClick={() => setIsOpen(false)}
                className="p-2 hover:bg-gray-100 rounded-lg transition-colors"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmit} className="p-6 space-y-6">
              {error && (
                <div className="bg-red-50 border border-red-200 text-red-700 px-4 py-3 rounded-lg">
                  {error}
                </div>
              )}
              {/* Category Selection */}
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  Kategoria
                </label>
                <div className="flex gap-4">
                  <button
                    type="button"
                    onClick={() => setCategory("kawa")}
                    className={`px-4 py-2 rounded-lg transition-colors ${
                      category === "kawa"
                        ? "bg-blue-600 text-white"
                        : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                    }`}
                  >
                    Kawa
                  </button>
                  <button
                    type="button"
                    onClick={() => setCategory("herbata")}
                    className={`px-4 py-2 rounded-lg transition-colors ${
                      category === "herbata"
                        ? "bg-blue-600 text-white"
                        : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                    }`}
                  >
                    Herbata
                  </button>
                  <button
                    type="button"
                    onClick={() => setCategory("dzieła-artystów")}
                    className={`px-4 py-2 rounded-lg transition-colors ${
                      category === "dzieła-artystów"
                        ? "bg-blue-600 text-white"
                        : "bg-gray-100 text-gray-700 hover:bg-gray-200"
                    }`}
                  >
                    Dzieła artystów
                  </button>
                </div>
              </div>

              {category === "kawa" ? (
                <div className="space-y-4" key="kawa">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Zdjęcia (max 5, max 3 MB każde)
                    </label>
                    <input
                      type="file"
                      accept="image/*"
                      multiple
                      onChange={(e) => {
                        const files = Array.from(e.target.files || []);
                        const validFiles = files.filter((file) => {
                          if (file.size > 3 * 1024 * 1024) {
                            alert(`Plik ${file.name} jest za duży. Maksymalny rozmiar to 3 MB.`);
                            return false;
                          }
                          return true;
                        });
                        if (coffeeData.images.length + validFiles.length > 5) {
                          alert("Można dodać maksymalnie 5 zdjęć.");
                          return;
                        }
                        setCoffeeData({ ...coffeeData, images: [...coffeeData.images, ...validFiles].slice(0, 5) });
                      }}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    {coffeeData.images.length > 0 && (
                      <div className="mt-2 space-y-2">
                        <div className="grid grid-cols-5 gap-2">
                          {coffeeData.images.map((file, index) => (
                            <div key={`${file.name}-${file.size}-${index}`} className="relative group">
                              <img
                                src={getImageUrl(file)}
                                alt={`Preview ${index + 1}`}
                                className="w-full h-20 object-cover rounded-lg border border-gray-200"
                                onError={(e) => {
                                  console.error('Error loading image:', file.name);
                                  (e.target as HTMLImageElement).src = '/placeholder-product.jpg';
                                }}
                              />
                              <button
                                type="button"
                                onClick={() => {
                                  setCoffeeData({
                                    ...coffeeData,
                                    images: coffeeData.images.filter((_, i) => i !== index),
                                  });
                                }}
                                className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600 opacity-0 group-hover:opacity-100 transition-opacity"
                              >
                                <X className="w-3 h-3" />
                              </button>
                            </div>
                          ))}
                        </div>
                        <p className="text-xs text-gray-500">
                          {coffeeData.images.length}/5 zdjęć
                        </p>
                      </div>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Nazwa *
                    </label>
                    <input
                      type="text"
                      required
                      value={coffeeData.name}
                      onChange={(e) => setCoffeeData({ ...coffeeData, name: e.target.value })}
                      placeholder="Nazwa kawy"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Cena (zł) *
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        required
                        value={coffeeData.price}
                        onChange={(e) => setCoffeeData({ ...coffeeData, price: e.target.value })}
                        placeholder="0.00"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Podatek VAT (%)
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        value={coffeeData.vatTax}
                        onChange={(e) => setCoffeeData({ ...coffeeData, vatTax: e.target.value })}
                        placeholder="23"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        SKU
                      </label>
                      <input
                        type="text"
                        value={coffeeData.sku}
                        onChange={(e) => setCoffeeData({ ...coffeeData, sku: e.target.value })}
                        placeholder="SKU-001"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Ilość *
                      </label>
                      <input
                        type="number"
                        required
                        value={coffeeData.quantity}
                        onChange={(e) => setCoffeeData({ ...coffeeData, quantity: e.target.value })}
                        placeholder="0"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Profil smakowy
                    </label>
                    <input
                      type="text"
                      value={coffeeData.flavorProfile}
                      onChange={(e) => setCoffeeData({ ...coffeeData, flavorProfile: e.target.value })}
                      placeholder="np. czekoladowy, orzechowy, owocowy"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Termin ważności
                      </label>
                      <input
                        type="date"
                        value={coffeeData.expiryDate}
                        onChange={(e) => setCoffeeData({ ...coffeeData, expiryDate: e.target.value })}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Kraj pochodzenia
                      </label>
                      <input
                        type="text"
                        value={coffeeData.originCountry}
                        onChange={(e) => setCoffeeData({ ...coffeeData, originCountry: e.target.value })}
                        placeholder="np. Kolumbia"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Profil palenia
                      </label>
                      <select
                        value={coffeeData.roastProfile}
                        onChange={(e) => setCoffeeData({ ...coffeeData, roastProfile: e.target.value })}
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      >
                        <option value="">Wybierz profil</option>
                        <option value="jasny">Jasny</option>
                        <option value="średni">Średni</option>
                        <option value="ciemny">Ciemny</option>
                      </select>
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Waga (g)
                      </label>
                      <input
                        type="number"
                        value={coffeeData.weight}
                        onChange={(e) => setCoffeeData({ ...coffeeData, weight: e.target.value })}
                        placeholder="250"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Opis
                    </label>
                    <textarea
                      value={coffeeData.description}
                      onChange={(e) => setCoffeeData({ ...coffeeData, description: e.target.value })}
                      rows={4}
                      placeholder="Szczegółowy opis produktu"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>
              ) : category === "herbata" ? (
                <div className="space-y-4" key="herbata">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Zdjęcia (max 5, max 3 MB każde)
                    </label>
                    <input
                      type="file"
                      accept="image/*"
                      multiple
                      onChange={(e) => {
                        const files = Array.from(e.target.files || []);
                        const validFiles = files.filter((file) => {
                          if (file.size > 3 * 1024 * 1024) {
                            alert(`Plik ${file.name} jest za duży. Maksymalny rozmiar to 3 MB.`);
                            return false;
                          }
                          return true;
                        });
                        if (teaData.images.length + validFiles.length > 5) {
                          alert("Można dodać maksymalnie 5 zdjęć.");
                          return;
                        }
                        setTeaData({ ...teaData, images: [...teaData.images, ...validFiles].slice(0, 5) });
                      }}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    {teaData.images.length > 0 && (
                      <div className="mt-2 space-y-2">
                        <div className="grid grid-cols-5 gap-2">
                          {teaData.images.map((file, index) => (
                            <div key={`${file.name}-${file.size}-${index}`} className="relative group">
                              <img
                                src={getImageUrl(file)}
                                alt={`Preview ${index + 1}`}
                                className="w-full h-20 object-cover rounded-lg border border-gray-200"
                                onError={(e) => {
                                  console.error('Error loading image:', file.name);
                                  (e.target as HTMLImageElement).src = '/placeholder-product.jpg';
                                }}
                              />
                              <button
                                type="button"
                                onClick={() => {
                                  setTeaData({
                                    ...teaData,
                                    images: teaData.images.filter((_, i) => i !== index),
                                  });
                                }}
                                className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600 opacity-0 group-hover:opacity-100 transition-opacity"
                              >
                                <X className="w-3 h-3" />
                              </button>
                            </div>
                          ))}
                        </div>
                        <p className="text-xs text-gray-500">
                          {teaData.images.length}/5 zdjęć
                        </p>
                      </div>
                    )}
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Nazwa *
                    </label>
                    <input
                      type="text"
                      required
                      value={teaData.name}
                      onChange={(e) => setTeaData({ ...teaData, name: e.target.value })}
                      placeholder="Nazwa herbaty"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Waga (g) *
                      </label>
                      <input
                        type="number"
                        required
                        value={teaData.weight}
                        onChange={(e) => setTeaData({ ...teaData, weight: e.target.value })}
                        placeholder="100"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Cena (zł) *
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        required
                        value={teaData.price}
                        onChange={(e) => setTeaData({ ...teaData, price: e.target.value })}
                        placeholder="0.00"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Ilość (szt.) *
                    </label>
                    <input
                      type="number"
                      required
                      value={teaData.quantity}
                      onChange={(e) => setTeaData({ ...teaData, quantity: e.target.value })}
                      placeholder="0"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Podatek VAT (%)
                    </label>
                    <input
                      type="number"
                      step="0.01"
                      value={teaData.vatTax}
                      onChange={(e) => setTeaData({ ...teaData, vatTax: e.target.value })}
                      placeholder="23"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Temperatura parzenia (°C)
                      </label>
                      <input
                        type="number"
                        value={teaData.brewingTemperature}
                        onChange={(e) => setTeaData({ ...teaData, brewingTemperature: e.target.value })}
                        placeholder="80"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Czas parzenia (min)
                      </label>
                      <input
                        type="number"
                        step="0.5"
                        value={teaData.brewingTime}
                        onChange={(e) => setTeaData({ ...teaData, brewingTime: e.target.value })}
                        placeholder="3-5"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Nuty smakowe
                    </label>
                    <input
                      type="text"
                      value={teaData.flavorNotes}
                      onChange={(e) => setTeaData({ ...teaData, flavorNotes: e.target.value })}
                      placeholder="np. kwiatowe, cytrusowe, ziołowe"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Kraj pochodzenia
                    </label>
                    <input
                      type="text"
                      value={teaData.originCountry}
                      onChange={(e) => setTeaData({ ...teaData, originCountry: e.target.value })}
                      placeholder="np. Chiny, Indie"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Opis
                    </label>
                    <textarea
                      value={teaData.description}
                      onChange={(e) => setTeaData({ ...teaData, description: e.target.value })}
                      rows={4}
                      placeholder="Szczegółowy opis herbaty"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>
              ) : (
                <div className="space-y-4">
                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Typ dzieła *
                    </label>
                    <select
                      value={artistWorkData.type}
                      onChange={(e) =>
                        setArtistWorkData({
                          ...artistWorkData,
                          type: e.target.value as "obraz" | "figurka" | "rękodzieło" | "inne",
                        })
                      }
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    >
                      <option value="obraz">Obraz</option>
                      <option value="figurka">Figurka</option>
                      <option value="rękodzieło">Rękodzieło</option>
                      <option value="inne">Inne</option>
                    </select>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Tytuł *
                    </label>
                    <input
                      type="text"
                      required
                      value={artistWorkData.title}
                      onChange={(e) =>
                        setArtistWorkData({ ...artistWorkData, title: e.target.value })
                      }
                      placeholder="Tytuł dzieła"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Zdjęcia (max 5, max 3 MB każde)
                    </label>
                    <input
                      type="file"
                      accept="image/*"
                      multiple
                      onChange={(e) => {
                        const files = Array.from(e.target.files || []);
                        const validFiles = files.filter((file) => {
                          if (file.size > 3 * 1024 * 1024) {
                            alert(`Plik ${file.name} jest za duży. Maksymalny rozmiar to 3 MB.`);
                            return false;
                          }
                          return true;
                        });
                        if (artistWorkData.images.length + validFiles.length > 5) {
                          alert("Można dodać maksymalnie 5 zdjęć.");
                          return;
                        }
                        setArtistWorkData({
                          ...artistWorkData,
                          images: [...artistWorkData.images, ...validFiles].slice(0, 5),
                        });
                      }}
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                    {artistWorkData.images.length > 0 && (
                      <div className="mt-2 space-y-2">
                        <div className="grid grid-cols-5 gap-2">
                          {artistWorkData.images.map((file, index) => (
                            <div key={`${file.name}-${file.size}-${index}`} className="relative group">
                              <img
                                src={getImageUrl(file)}
                                alt={`Preview ${index + 1}`}
                                className="w-full h-20 object-cover rounded-lg border border-gray-200"
                                onError={(e) => {
                                  console.error('Error loading image:', file.name);
                                  (e.target as HTMLImageElement).src = '/placeholder-product.jpg';
                                }}
                              />
                              <button
                                type="button"
                                onClick={() => {
                                  setArtistWorkData({
                                    ...artistWorkData,
                                    images: artistWorkData.images.filter((_, i) => i !== index),
                                  });
                                }}
                                className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600 opacity-0 group-hover:opacity-100 transition-opacity"
                              >
                                <X className="w-3 h-3" />
                              </button>
                            </div>
                          ))}
                        </div>
                        <p className="text-xs text-gray-500">
                          {artistWorkData.images.length}/5 zdjęć
                        </p>
                      </div>
                    )}
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Cena (zł) *
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        required
                        value={artistWorkData.price}
                        onChange={(e) =>
                          setArtistWorkData({ ...artistWorkData, price: e.target.value })
                        }
                        placeholder="0.00"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Podatek VAT (%)
                      </label>
                      <input
                        type="number"
                        step="0.01"
                        value={artistWorkData.vatTax}
                        onChange={(e) =>
                          setArtistWorkData({ ...artistWorkData, vatTax: e.target.value })
                        }
                        placeholder="23"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-4">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Waga (g)
                      </label>
                      <input
                        type="number"
                        value={artistWorkData.weight}
                        onChange={(e) =>
                          setArtistWorkData({ ...artistWorkData, weight: e.target.value })
                        }
                        placeholder="0"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-2">
                        Kraj pochodzenia
                      </label>
                      <input
                        type="text"
                        value={artistWorkData.originCountry}
                        onChange={(e) =>
                          setArtistWorkData({ ...artistWorkData, originCountry: e.target.value })
                        }
                        placeholder="np. Polska"
                        className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                      />
                    </div>
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Imię i nazwisko artysty *
                    </label>
                    <input
                      type="text"
                      required
                      value={artistWorkData.artistName}
                      onChange={(e) =>
                        setArtistWorkData({ ...artistWorkData, artistName: e.target.value })
                      }
                      placeholder="Jan Kowalski"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Linki do sociali artysty (jeden na linię)
                    </label>
                    <textarea
                      value={artistWorkData.artistSocialLinks.join("\n")}
                      onChange={(e) =>
                        setArtistWorkData({
                          ...artistWorkData,
                          artistSocialLinks: e.target.value
                            .split("\n")
                            .filter((link) => link.trim()),
                        })
                      }
                      rows={3}
                      placeholder="https://instagram.com/artist&#10;https://facebook.com/artist"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>

                  <div>
                    <label className="block text-sm font-medium text-gray-700 mb-2">
                      Opis
                    </label>
                    <textarea
                      value={artistWorkData.description}
                      onChange={(e) =>
                        setArtistWorkData({ ...artistWorkData, description: e.target.value })
                      }
                      rows={4}
                      placeholder="Szczegółowy opis dzieła"
                      className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                    />
                  </div>
                </div>
              )}

              <div className="flex justify-end gap-4 pt-4 border-t border-gray-200">
                <button
                  type="button"
                  onClick={() => setIsOpen(false)}
                  className="px-6 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
                >
                  Anuluj
                </button>
                <button
                  type="submit"
                  disabled={isSubmitting}
                  className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
                >
                  {isSubmitting ? 'Dodawanie...' : 'Dodaj produkt'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </>
  );
}

