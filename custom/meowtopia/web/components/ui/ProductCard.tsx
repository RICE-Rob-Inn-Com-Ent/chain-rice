'use client'

import { useState, useEffect } from 'react'
import Image from 'next/image'
import { Icon } from '@iconify/react'
import { useCartStore } from '@/lib/store/cart'

interface Product {
  id: string
  name: string
  price: number
  category?: string // Tymczasowo dla kompatybilności
  categoryName?: string // Nazwa kategorii z bazy danych
  categorySlug?: string // Slug kategorii z bazy danych
  images: string[]
  featured?: boolean
  description?: string
  details?: {
    currentBeans?: string
    origin?: string
    roastProfile?: string
    processing?: string
    region?: string
    flavorProfile?: string
    variety?: string
    weight?: string
    composition?: string
    idealFor?: string
    brewingTemperature?: string
  }
}

interface ProductCardProps {
  product: Product
  showDonation?: boolean
}

export default function ProductCard({ product, showDonation = true }: ProductCardProps) {
  const addItem = useCartStore((state) => state.addItem)
  const updateQuantity = useCartStore((state) => state.updateQuantity)
  const items = useCartStore((state) => state.items)
  const [showModal, setShowModal] = useState(false)
  const [selectedImageIndex, setSelectedImageIndex] = useState(0)

  const donationAmount = (product.price * 0.05).toFixed(2)

  // Blokuj przewijanie strony gdy modal jest otwarty
  useEffect(() => {
    if (showModal) {
      // Zapisz aktualną pozycję scroll
      const scrollY = window.scrollY
      // Zablokuj przewijanie
      document.body.style.position = 'fixed'
      document.body.style.top = `-${scrollY}px`
      document.body.style.width = '100%'
      document.body.style.overflow = 'hidden'
      
      return () => {
        // Przywróć przewijanie
        document.body.style.position = ''
        document.body.style.top = ''
        document.body.style.width = ''
        document.body.style.overflow = ''
        window.scrollTo(0, scrollY)
      }
    }
  }, [showModal])

  // Find current quantity in cart
  const cartItem = items.find(item => item.id === product.id)
  const cartQuantity = cartItem?.quantity || 0

  const handleIncrement = () => {
    addItem({
      id: product.id,
      name: product.name,
      price: product.price,
      image: product.images[0] || '/placeholder-product.jpg',
      category: product.categorySlug?.toUpperCase() || product.category || 'OTHER'
    })
  }

  const handleDecrement = () => {
    if (cartQuantity > 1) {
      updateQuantity(product.id, cartQuantity - 1)
    } else if (cartQuantity === 1) {
      updateQuantity(product.id, 0) // remove item when hitting zero
    }
  }

  // Użyj categoryName z bazy danych lub fallback do starego systemu
  const categoryLabel = product.categoryName || (product.category ? {
    COFFEE: 'Kawa',
    TEA: 'Herbata',
    ILLUSTRATION: 'Ilustracja'
  }[product.category as 'COFFEE' | 'TEA' | 'ILLUSTRATION'] : 'Produkt')

  // Kolory kategorii - można później rozszerzyć o kolory w bazie danych
  const getCategoryColor = () => {
    if (product.categorySlug) {
      // Domyślne kolory na podstawie slug
      if (product.categorySlug.includes('coffee') || product.categorySlug.includes('kawa')) {
        return 'bg-amber-100 text-amber-800'
      }
      if (product.categorySlug.includes('tea') || product.categorySlug.includes('herbata')) {
        return 'bg-green-100 text-green-800'
      }
      if (product.categorySlug.includes('illustration') || product.categorySlug.includes('ilustrac')) {
        return 'bg-purple-100 text-purple-800'
      }
    }
    // Fallback do starego systemu
    if (product.category) {
      const colors: Record<string, string> = {
        COFFEE: 'bg-amber-100 text-amber-800',
        TEA: 'bg-green-100 text-green-800',
        ILLUSTRATION: 'bg-purple-100 text-purple-800'
      }
      return colors[product.category] || 'bg-gray-100 text-gray-800'
    }
    return 'bg-gray-100 text-gray-800'
  }

  return (
    <div className="border border-[#F97316] rounded-2xl p-4 bg-white shadow-sm">
      <div className="relative">
        {/* Product image */}
        <div className="relative aspect-square overflow-hidden rounded-2xl mb-4" style={{ position: 'relative' }}>
          <Image
            src={product.images[0] || '/placeholder-tea1.jpg'}
            alt={product.name}
            fill
            sizes="(max-width: 768px) 100vw, (max-width: 1200px) 50vw, 33vw"
            className="object-cover transition-transform duration-500"
          />

          {/* Featured badge */}
          {product.featured && (
            <div className="absolute top-3 left-3">
              <span className="bg-accent text-white px-3 py-1 rounded-full text-xs font-medium">
                ⭐ Polecane
              </span>
            </div>
          )}

          {/* Category badge */}
          <div className="absolute top-3 right-3">
            <span className={`px-3 py-1 rounded-full text-xs font-medium ${getCategoryColor()}`}>
              {categoryLabel}
            </span>
          </div>


        </div>

        {/* Product info */}
        <div className="space-y-3 text-center">
          {/* Nazwa produktu */}
          <h3 className="font-heading font-semibold text-graphite-800 transition-colors text-lg">
            {product.name}
          </h3>

          {/* Waga produktu */}
          {product.details?.weight ? (
            <p className="text-sm text-graphite-600">
              Waga: {product.details.weight}
            </p>
          ) : (
            <p className="text-sm text-graphite-600">
              {product.categorySlug?.includes('illustration') || product.category === 'ILLUSTRATION' ? 'Format: A4' : 'Waga: 100g'}
            </p>
          )}

          {/* Cena produktu */}
          <div className="mb-4">
            <span className="text-2xl font-bold text-primary">
              {product.price.toFixed(2)} zł
            </span>
          </div>

          {/* Przyciski akcji */}
          <div className="flex items-center space-x-3">
            <button
              type="button"
              onClick={() => {
                setSelectedImageIndex(0)
                setShowModal(true)
              }}
              className="w-1/2 min-h-[48px] flex items-center justify-center rounded-2xl font-semibold transition-all duration-300 shadow-md hover:shadow-lg transform hover:scale-[1.01] border border-[#F97316]/70 text-[#F97316] bg-white hover:bg-orange-50 active:bg-[#F97316] active:text-white text-sm px-4"
            >
              Czytaj więcej
            </button>
            <div className="w-1/2 min-h-[48px] flex items-center justify-center rounded-2xl px-2 shadow-md border border-[#F97316]/60 bg-white hover:bg-orange-50 transition-all">
              <button
                onClick={handleDecrement}
                className="w-10 h-10 flex items-center justify-center text-[#F97316] hover:bg-orange-100 active:bg-[#F97316] active:text-white rounded-xl transition-colors"
                title="Usuń z koszyka"
              >
                <Icon icon="material-symbols:remove" className="w-4 h-4 rounded" />
              </button>
              <span className="px-3 py-2 text-[#F97316] font-medium min-w-[2rem] text-center">
                {cartQuantity}
              </span>
              <button
                onClick={handleIncrement}
                className="w-10 h-10 flex items-center justify-center text-[#F97316] hover:bg-orange-100 active:bg-[#F97316] active:text-white rounded-xl transition-colors"
                title="Dodaj do koszyka"
              >
                <Icon icon="material-symbols:add" className="w-4 h-4 rounded" />
              </button>
            </div>
          </div>
        </div>
      </div>

      {showModal && (
        <>
          {/* Overlay z przyciemnieniem */}
          <div
            className="fixed inset-0 z-[9998] bg-black/70 backdrop-blur-sm transition-opacity"
            onClick={() => setShowModal(false)}
            aria-hidden="true"
          />
          
          {/* Modal */}
          <div
            className="fixed inset-0 z-[9999] flex items-center justify-center px-4 pointer-events-none"
            onClick={() => setShowModal(false)}
          >
            <div
              className="bg-white rounded-2xl shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto p-6 relative pointer-events-auto transform transition-all duration-300 ease-out"
              style={{
                animation: 'fade-in 0.3s ease-out, slide-up 0.3s ease-out'
              } as React.CSSProperties}
              onClick={(e) => e.stopPropagation()}
              role="dialog"
              aria-modal="true"
              aria-labelledby={`modal-title-${product.id}`}
              onWheel={(e) => {
                // Zatrzymaj propagację scrolla na modal, ale pozwól scrollować wewnątrz
                const target = e.currentTarget
                const isScrollable = target.scrollHeight > target.clientHeight
                const isAtTop = target.scrollTop === 0
                const isAtBottom = target.scrollTop + target.clientHeight === target.scrollHeight
                
                if (!isScrollable || (isAtTop && e.deltaY < 0) || (isAtBottom && e.deltaY > 0)) {
                  e.stopPropagation()
                }
              }}
            >
            <button
              type="button"
              className="absolute top-3 right-3 text-graphite-500 hover:text-graphite-800 z-10"
              onClick={() => setShowModal(false)}
              aria-label="Zamknij"
            >
              ×
            </button>
            
            {/* Galeria zdjęć */}
            {product.images && product.images.length > 0 && (
              <div className="mb-6">
                <div className="relative aspect-square bg-gray-100 rounded-xl overflow-hidden mb-4">
                  <Image
                    src={product.images[selectedImageIndex] || product.images[0] || '/placeholder-product.jpg'}
                    alt={product.name}
                    fill
                    sizes="(max-width: 768px) 100vw, 600px"
                    className="object-cover"
                  />
                  {/* Przyciski nawigacji zdjęć */}
                  {product.images.length > 1 && (
                    <>
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation()
                          setSelectedImageIndex((prev) =>
                            prev === 0 ? product.images.length - 1 : prev - 1
                          )
                        }}
                        className="absolute left-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 text-white p-2 rounded-full transition-colors"
                        aria-label="Poprzednie zdjęcie"
                      >
                        <Icon icon="material-symbols:chevron-left" className="w-6 h-6" />
                      </button>
                      <button
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation()
                          setSelectedImageIndex((prev) =>
                            prev === product.images.length - 1 ? 0 : prev + 1
                          )
                        }}
                        className="absolute right-2 top-1/2 -translate-y-1/2 bg-black/50 hover:bg-black/70 text-white p-2 rounded-full transition-colors"
                        aria-label="Następne zdjęcie"
                      >
                        <Icon icon="material-symbols:chevron-right" className="w-6 h-6" />
                      </button>
                    </>
                  )}
                </div>
                {/* Miniaturki zdjęć */}
                {product.images.length > 1 && (
                  <div className="flex gap-2 overflow-x-auto pb-2">
                    {product.images.map((image, index) => (
                      <button
                        key={index}
                        type="button"
                        onClick={(e) => {
                          e.stopPropagation()
                          setSelectedImageIndex(index)
                        }}
                        className={`relative w-20 h-20 flex-shrink-0 rounded-lg overflow-hidden border-2 transition-all ${
                          selectedImageIndex === index
                            ? 'border-[#F97316] ring-2 ring-[#F97316]/20'
                            : 'border-gray-200 hover:border-gray-300'
                        }`}
                      >
                        <Image
                          src={image}
                          alt={`${product.name} - zdjęcie ${index + 1}`}
                          fill
                          sizes="80px"
                          className="object-cover"
                        />
                      </button>
                    ))}
                  </div>
                )}
              </div>
            )}

            <h3 id={`modal-title-${product.id}`} className="text-2xl font-semibold text-graphite-800 mb-4">
              {product.name}
            </h3>

            {/* Szczegóły produktu */}
            <div className="space-y-2 mb-4">
              {product.details?.weight && (
                <p className="text-sm text-graphite-600">
                  <span className="font-medium">Waga:</span> {product.details.weight}
                </p>
              )}
              {product.details?.roastProfile && (
                <p className="text-sm text-graphite-600">
                  <span className="font-medium">Profil palenia:</span> {product.details.roastProfile}
                </p>
              )}
              {product.details?.flavorProfile && (
                <p className="text-sm text-graphite-600">
                  <span className="font-medium">Profil smakowy:</span> {product.details.flavorProfile}
                </p>
              )}
              {product.details?.origin && (
                <p className="text-sm text-graphite-600">
                  <span className="font-medium">Pochodzenie:</span> {product.details.origin}
                </p>
              )}
              {product.details?.brewingTemperature && (
                <p className="text-sm text-graphite-600">
                  <span className="font-medium">Temperatura parzenia:</span> {product.details.brewingTemperature}°C
                </p>
              )}
              {product.details?.idealFor && (
                <p className="text-sm text-graphite-600">
                  <span className="font-medium">Idealna pod:</span> {product.details.idealFor}
                </p>
              )}
            </div>

            {product.description && (
              <div className="mb-4">
                <h4 className="text-sm font-semibold text-graphite-800 mb-2">Opis</h4>
                <p className="text-sm text-graphite-700 leading-relaxed">{product.description}</p>
              </div>
            )}

            <div className="mt-6 flex items-center justify-between pt-4 border-t border-gray-200">
              <span className="text-2xl font-bold text-[#F97316]">{product.price.toFixed(2)} zł</span>
              <button
                type="button"
                onClick={() => {
                  handleIncrement()
                  setShowModal(false)
                }}
                className="flex items-center gap-2 px-6 py-3 rounded-xl bg-[#F97316] text-white font-semibold hover:bg-orange-500 transition-colors"
              >
                Dodaj do koszyka
              </button>
            </div>
            </div>
          </div>
        </>
      )}
    </div>
  )
}
