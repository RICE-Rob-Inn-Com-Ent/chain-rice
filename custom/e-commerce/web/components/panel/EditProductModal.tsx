"use client";

import { useState, useEffect, useMemo } from "react";
import { X } from "lucide-react";
import { useRouter } from "next/navigation";
// Prisma types - will be available after running: yarn prisma generate
// @ts-ignore - Prisma types not generated yet
import type { Product } from "@prisma/client";

type ProductCategory = "kawa" | "herbata" | "dzieła-artystów";

interface EditProductModalProps {
  product: Product & {
    category: { id: string; name: string; slug: string } | null;
  };
  isOpen: boolean;
  onClose: () => void;
}

export default function EditProductModal({ product, isOpen, onClose }: EditProductModalProps) {
  const router = useRouter();
  const [category, setCategory] = useState<ProductCategory>(() => {
    const slug = product.category?.slug || "";
    if (slug.includes("kawa") || slug === "kawa") return "kawa";
    if (slug.includes("herbata") || slug === "herbata") return "herbata";
    if (slug.includes("dzieła") || slug.includes("artyst")) return "dzieła-artystów";
    return "kawa";
  });
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);
  
  // Cache dla URL-i obrazów
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

  // Stan dla istniejących obrazów (URL-e) i nowych (File)
  const [existingImages, setExistingImages] = useState<string[]>(product.images || []);
  const [newImages, setNewImages] = useState<File[]>([]);

  // Kawa fields
  const [coffeeData, setCoffeeData] = useState({
    name: product.name || "",
    images: [] as File[],
    flavorProfile: (product as any).flavorProfile || "",
    price: product.price.toString() || "",
    vatTax: (product as any).vatTax || "",
    sku: (product as any).sku || "",
    quantity: product.stock.toString() || "",
    expiryDate: (product as any).expiryDate || "",
    originCountry: (product as any).originCountry || "",
    roastProfile: (product as any).roastProfile || "",
    weight: product.weight?.toString() || "",
    description: product.description || "",
  });

  // Herbata fields
  const [teaData, setTeaData] = useState({
    name: product.name || "",
    images: [] as File[],
    weight: product.weight?.toString() || "",
    price: product.price.toString() || "",
    vatTax: (product as any).vatTax || "",
    quantity: product.stock.toString() || "",
    brewingTemperature: (product as any).brewingTemperature || "",
    brewingTime: (product as any).brewingTime || "",
    flavorNotes: (product as any).flavorNotes || "",
    description: product.description || "",
    originCountry: (product as any).originCountry || "",
  });

  // Dzieła artystów fields
  const [artistWorkData, setArtistWorkData] = useState({
    type: ((product as any).artworkType || "obraz") as "obraz" | "figurka" | "rękodzieło" | "inne",
    title: product.name || "",
    images: [] as File[],
    price: product.price.toString() || "",
    vatTax: (product as any).vatTax || "",
    weight: product.weight?.toString() || "",
    originCountry: (product as any).originCountry || "",
    description: product.description || "",
    artistName: (product as any).artistName || "",
    artistSocialLinks: (product as any).artistSocialLinks || [],
  });

  // Inicjalizuj dane przy otwarciu
  useEffect(() => {
    if (isOpen && product) {
      const images = product.images || [];
      console.log('[EditProductModal] Initializing with product:', {
        id: product.id,
        name: product.name,
        imagesCount: images.length,
        images: images
      });
      setExistingImages(images);
      setNewImages([]);
      setError(null);
    }
  }, [isOpen, product]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      // Logowanie stanu przed zapisaniem
      console.log('[EditProductModal] Submitting form:', {
        category,
        existingImagesCount: existingImages.length,
        existingImages,
        coffeeDataImagesCount: coffeeData.images.length,
        coffeeDataImages: coffeeData.images,
        teaDataImagesCount: teaData.images.length,
        teaDataImages: teaData.images,
        artistWorkDataImagesCount: artistWorkData.images.length,
        artistWorkDataImages: artistWorkData.images,
      });

      // Funkcja do uploadu nowych zdjęć
      const uploadImages = async (images: File[], productName: string, categoryType: string): Promise<string[]> => {
        if (!images || images.length === 0) {
          console.log('[EditProductModal] No images to upload');
          return [];
        }

        console.log('[EditProductModal] Starting upload:', { imagesCount: images.length, productName, categoryType });
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
          console.error('[EditProductModal] Upload failed:', errorData);
          throw new Error(errorData.error || 'Failed to upload images');
        }

        const result = await uploadResponse.json();
        const urls = result.urls || [];
        console.log('[EditProductModal] Upload API response:', { success: result.success, urlsCount: urls.length, urls });
        
        if (urls.length === 0 && images.length > 0) {
          console.error('[EditProductModal] Upload succeeded but no URLs returned');
          throw new Error('Przesyłanie zakończone, ale nie otrzymano adresów URL zdjęć');
        }
        
        return urls;
      };

      // Upload nowych zdjęć dla odpowiedniej kategorii
      let newImageUrls: string[] = [];
      if (category === 'kawa' && coffeeData.images.length > 0 && coffeeData.name) {
        console.log('[EditProductModal] Uploading new images for kawa:', coffeeData.images.length, 'files');
        newImageUrls = await uploadImages(coffeeData.images, coffeeData.name, 'kawa');
        console.log('[EditProductModal] Uploaded new image URLs:', newImageUrls);
      } else if (category === 'herbata' && teaData.images.length > 0 && teaData.name) {
        console.log('[EditProductModal] Uploading new images for herbata:', teaData.images.length, 'files');
        newImageUrls = await uploadImages(teaData.images, teaData.name, 'herbata');
        console.log('[EditProductModal] Uploaded new image URLs:', newImageUrls);
      } else if (category === 'dzieła-artystów' && artistWorkData.images.length > 0 && artistWorkData.title) {
        console.log('[EditProductModal] Uploading new images for dzieła-artystów:', artistWorkData.images.length, 'files');
        newImageUrls = await uploadImages(artistWorkData.images, artistWorkData.title, 'dzieła-artystów');
        console.log('[EditProductModal] Uploaded new image URLs:', newImageUrls);
      } else {
        console.log('[EditProductModal] No new images to upload. Condition check:', {
          category,
          'kawa': { hasImages: coffeeData.images.length > 0, hasName: !!coffeeData.name },
          'herbata': { hasImages: teaData.images.length > 0, hasName: !!teaData.name },
          'dzieła-artystów': { hasImages: artistWorkData.images.length > 0, hasTitle: !!artistWorkData.title },
        });
      }

      // Połącz istniejące obrazy (które nie zostały usunięte) z nowymi
      const allImageUrls = [...existingImages, ...newImageUrls];
      console.log('[EditProductModal] Combined image URLs:', {
        existingImagesCount: existingImages.length,
        newImageUrlsCount: newImageUrls.length,
        allImageUrlsCount: allImageUrls.length,
        allImageUrls,
      });

      // Przygotuj dane do wysłania
      let productData: any = {
        images: allImageUrls.length > 0 ? allImageUrls : existingImages,
      };

      if (category === 'kawa') {
        productData = {
          name: coffeeData.name,
          price: coffeeData.price,
          stock: parseInt(coffeeData.quantity) || 0,
          description: coffeeData.description || null,
          weight: coffeeData.weight ? parseFloat(coffeeData.weight) : null,
          images: allImageUrls.length > 0 ? allImageUrls : existingImages,
          roastProfile: coffeeData.roastProfile || null,
          flavorProfile: coffeeData.flavorProfile || null,
          originCountry: coffeeData.originCountry || null,
        };
      } else if (category === 'herbata') {
        productData = {
          name: teaData.name,
          price: teaData.price,
          stock: parseInt(teaData.quantity) || 0,
          description: teaData.description || null,
          weight: teaData.weight ? parseFloat(teaData.weight) : null,
          images: allImageUrls.length > 0 ? allImageUrls : existingImages,
          brewingTemperature: teaData.brewingTemperature || null,
          brewingTime: teaData.brewingTime || null,
          flavorNotes: teaData.flavorNotes || null,
          originCountry: teaData.originCountry || null,
        };
      } else if (category === 'dzieła-artystów') {
        productData = {
          name: artistWorkData.title,
          price: artistWorkData.price,
          stock: 1,
          description: artistWorkData.description || null,
          weight: artistWorkData.weight ? parseFloat(artistWorkData.weight) : null,
          images: allImageUrls.length > 0 ? allImageUrls : existingImages,
        };
      }

      console.log('[EditProductModal] Sending product data to API:', productData);

      const response = await fetch(`/api/products/${product.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(productData),
      });

      if (!response.ok) {
        const errorData = await response.json();
        throw new Error(errorData.error || 'Failed to update product');
      }

      onClose();
      router.refresh();
    } catch (err) {
      console.error('Error updating product:', err);
      setError(err instanceof Error ? err.message : 'Failed to update product');
    } finally {
      setIsSubmitting(false);
    }
  };

  if (!isOpen) return null;

  const renderImagePreview = (images: File[], existingUrls: string[], onRemoveNew: (index: number) => void, onRemoveExisting: (index: number) => void) => {
    console.log('[EditProductModal] Rendering image preview:', { existingUrls, newImagesCount: images.length });
    
    return (
      <div className="mt-2 space-y-2">
        {(existingUrls.length > 0 || images.length > 0) && (
          <div className="grid grid-cols-5 gap-2">
            {/* Istniejące obrazy */}
            {existingUrls.map((url, index) => {
              console.log(`[EditProductModal] Rendering existing image ${index}:`, url);
              return (
                <div key={`existing-${index}-${url}`} className="relative group">
                  <img
                    src={url}
                    alt={`Zdjęcie ${index + 1}`}
                    className="w-full h-20 object-cover rounded-lg border border-gray-200"
                    onError={(e) => {
                      console.error('[EditProductModal] Error loading existing image:', url);
                      const img = e.target as HTMLImageElement;
                      img.src = '/placeholder-product.jpg';
                      img.alt = 'Nie można załadować zdjęcia';
                    }}
                    onLoad={() => {
                      console.log('[EditProductModal] Successfully loaded existing image:', url);
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => {
                      console.log('[EditProductModal] Removing existing image:', index, url);
                      onRemoveExisting(index);
                    }}
                    className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600 opacity-0 group-hover:opacity-100 transition-opacity z-10"
                    title="Usuń zdjęcie"
                  >
                    <X className="w-3 h-3" />
                  </button>
                </div>
              );
            })}
            {/* Nowe obrazy */}
            {images.map((file, index) => {
              const previewUrl = getImageUrl(file);
              console.log(`[EditProductModal] Rendering new image ${index}:`, file.name, previewUrl);
              return (
                <div key={`new-${index}-${file.name}-${file.size}`} className="relative group">
                  <img
                    src={previewUrl}
                    alt={`Nowe zdjęcie ${index + 1}`}
                    className="w-full h-20 object-cover rounded-lg border border-gray-200"
                    onError={(e) => {
                      console.error('[EditProductModal] Error loading new image:', file.name);
                      const img = e.target as HTMLImageElement;
                      img.src = '/placeholder-product.jpg';
                      img.alt = 'Nie można załadować zdjęcia';
                    }}
                    onLoad={() => {
                      console.log('[EditProductModal] Successfully loaded new image:', file.name);
                    }}
                  />
                  <button
                    type="button"
                    onClick={() => {
                      console.log('[EditProductModal] Removing new image:', index, file.name);
                      onRemoveNew(index);
                    }}
                    className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600 opacity-0 group-hover:opacity-100 transition-opacity z-10"
                    title="Usuń zdjęcie"
                  >
                    <X className="w-3 h-3" />
                  </button>
                </div>
              );
            })}
          </div>
        )}
        <p className="text-xs text-gray-500">
          {existingUrls.length + images.length}/5 zdjęć
        </p>
      </div>
    );
  };

  return (
    <div className="fixed inset-0 bg-black bg-opacity-50 z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-xl shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto">
        <div className="sticky top-0 bg-white border-b border-gray-200 px-6 py-4 flex items-center justify-between">
          <h2 className="text-2xl font-bold text-gray-900">Edytuj produkt</h2>
          <button
            onClick={onClose}
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

          {/* Category Selection - tylko do wyświetlenia, nie można zmieniać */}
          <div>
            <label className="block text-sm font-medium text-gray-700 mb-2">
              Kategoria (nie można zmienić)
            </label>
            <div className="px-4 py-2 bg-gray-100 rounded-lg text-gray-700">
              {category === "kawa" ? "Kawa" : category === "herbata" ? "Herbata" : "Dzieła artystów"}
            </div>
          </div>

          {category === "kawa" ? (
            <div className="space-y-4">
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
                    console.log('[EditProductModal] Files selected for kawa:', files.length, files.map(f => f.name));
                    const validFiles = files.filter((file) => {
                      if (file.size > 3 * 1024 * 1024) {
                        alert(`Plik ${file.name} jest za duży. Maksymalny rozmiar to 3 MB.`);
                        return false;
                      }
                      return true;
                    });
                    if (existingImages.length + coffeeData.images.length + validFiles.length > 5) {
                      alert("Można dodać maksymalnie 5 zdjęć.");
                      return;
                    }
                    const newImages = [...coffeeData.images, ...validFiles].slice(0, 5);
                    console.log('[EditProductModal] Setting coffeeData.images:', {
                      previousCount: coffeeData.images.length,
                      newCount: newImages.length,
                      newImages: newImages.map(f => f.name),
                    });
                    setCoffeeData({ ...coffeeData, images: newImages });
                    // Reset input aby można było wybrać ten sam plik ponownie
                    e.target.value = '';
                  }}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                {renderImagePreview(
                  coffeeData.images,
                  existingImages,
                  (index) => setCoffeeData({ ...coffeeData, images: coffeeData.images.filter((_, i) => i !== index) }),
                  (index) => setExistingImages(existingImages.filter((_, i) => i !== index))
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
            <div className="space-y-4">
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
                    console.log('[EditProductModal] Files selected for herbata:', files.length, files.map(f => f.name));
                    const validFiles = files.filter((file) => {
                      if (file.size > 3 * 1024 * 1024) {
                        alert(`Plik ${file.name} jest za duży. Maksymalny rozmiar to 3 MB.`);
                        return false;
                      }
                      return true;
                    });
                    if (existingImages.length + teaData.images.length + validFiles.length > 5) {
                      alert("Można dodać maksymalnie 5 zdjęć.");
                      return;
                    }
                    const newImages = [...teaData.images, ...validFiles].slice(0, 5);
                    console.log('[EditProductModal] Setting teaData.images:', {
                      previousCount: teaData.images.length,
                      newCount: newImages.length,
                      newImages: newImages.map(f => f.name),
                    });
                    setTeaData({ ...teaData, images: newImages });
                    // Reset input aby można było wybrać ten sam plik ponownie
                    e.target.value = '';
                  }}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                {renderImagePreview(
                  teaData.images,
                  existingImages,
                  (index) => setTeaData({ ...teaData, images: teaData.images.filter((_, i) => i !== index) }),
                  (index) => setExistingImages(existingImages.filter((_, i) => i !== index))
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
                <div>
                  <label className="block text-sm font-medium text-gray-700 mb-2">
                    Ilość *
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
                    console.log('[EditProductModal] Files selected for dzieła-artystów:', files.length, files.map(f => f.name));
                    const validFiles = files.filter((file) => {
                      if (file.size > 3 * 1024 * 1024) {
                        alert(`Plik ${file.name} jest za duży. Maksymalny rozmiar to 3 MB.`);
                        return false;
                      }
                      return true;
                    });
                    if (existingImages.length + artistWorkData.images.length + validFiles.length > 5) {
                      alert("Można dodać maksymalnie 5 zdjęć.");
                      return;
                    }
                    const newImages = [...artistWorkData.images, ...validFiles].slice(0, 5);
                    console.log('[EditProductModal] Setting artistWorkData.images:', {
                      previousCount: artistWorkData.images.length,
                      newCount: newImages.length,
                      newImages: newImages.map(f => f.name),
                    });
                    setArtistWorkData({
                      ...artistWorkData,
                      images: newImages,
                    });
                    // Reset input aby można było wybrać ten sam plik ponownie
                    e.target.value = '';
                  }}
                  className="w-full px-4 py-2 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                {renderImagePreview(
                  artistWorkData.images,
                  existingImages,
                  (index) => setArtistWorkData({
                    ...artistWorkData,
                    images: artistWorkData.images.filter((_, i) => i !== index),
                  }),
                  (index) => setExistingImages(existingImages.filter((_, i) => i !== index))
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
                    Ilość *
                  </label>
                  <input
                    type="number"
                    required
                    value="1"
                    disabled
                    className="w-full px-4 py-2 border border-gray-300 rounded-lg bg-gray-100 text-gray-500"
                  />
                </div>
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
              onClick={onClose}
              className="px-6 py-2 border border-gray-300 rounded-lg hover:bg-gray-50 transition-colors"
            >
              Anuluj
            </button>
            <button
              type="submit"
              disabled={isSubmitting}
              className="px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700 transition-colors font-medium disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isSubmitting ? 'Zapisywanie...' : 'Zapisz zmiany'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
}

