'use client'

import { useState } from 'react'
import Image from 'next/image'
import Link from 'next/link'
import { useCartStore } from '@/lib/store/cart'
import { getProductById, Product } from '@/lib/products'
import { notFound } from 'next/navigation'
import {
  ShoppingBag,
  Heart,
  Minus,
  Plus,
  ArrowLeft,
  Share2,
  ChevronLeft,
  ChevronRight
} from 'lucide-react'

export default function ProductPage({ params }: { params: { id: string } }) {
  const product = getProductById(params.id)

  if (!product) {
    notFound()
  }

  const [selectedImageIndex, setSelectedImageIndex] = useState(0)
  const [quantity, setQuantity] = useState(1)
  const [selectedTab, setSelectedTab] = useState<'description' | 'shipping'>('description')

  const addItem = useCartStore((state) => state.addItem)

  const totalPrice = product.price * quantity

  const handleAddToCart = () => {
    addItem({
      id: product.id,
      name: product.name,
      price: product.price,
      image: product.images[0] || '/placeholder-product.jpg',
      category: product.category
    }, quantity)
  }

  const handleQuantityChange = (newQuantity: number) => {
    if (newQuantity >= 1 && newQuantity <= 25) { // Default stock for all products
      setQuantity(newQuantity)
    }
  }

  const nextImage = () => {
    setSelectedImageIndex((prev) =>
      prev === product.images.length - 1 ? 0 : prev + 1
    )
  }

  const prevImage = () => {
    setSelectedImageIndex((prev) =>
      prev === 0 ? product.images.length - 1 : prev - 1
    )
  }

  return (
    <div className="min-h-screen bg-cream">

      {/* Breadcrumb */}
      <div className="bg-white/50 py-4">
        <div className="max-w-7xl mx-auto container-padding">
          <div className="flex items-center space-x-2 text-sm text-graphite-600">
            <Link href="/" className="hover:text-primary transition-colors">Strona główna</Link>
            <span>/</span>
            <Link href="/products" className="hover:text-primary transition-colors">Produkty</Link>
            <span>/</span>
            <Link href="/kawa" className="hover:text-primary transition-colors">
              {product.category === 'COFFEE' ? 'Kawy' : product.category === 'TEA' ? 'Herbaty' : 'Ilustracje'}
            </Link>
            <span>/</span>
            <span className="text-primary font-medium">{product.name}</span>
          </div>
        </div>
      </div>

      <div className="max-w-7xl mx-auto container-padding py-8">

        {/* Back button */}
        <Link
          href="/products"
          className="inline-flex items-center space-x-2 text-graphite-600 hover:text-primary mb-8 group transition-colors"
        >
          <ArrowLeft className="w-4 h-4 group-hover:-translate-x-1 transition-transform" />
          <span>Powrót do produktów</span>
        </Link>

        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 mb-12">

          {/* Product Images */}
          <div className="space-y-4">
            {/* Main image */}
            <div className="relative aspect-square bg-white rounded-3xl overflow-hidden shadow-medium group">
              <Image
                src={product.images[selectedImageIndex]}
                alt={product.name}
                fill
                className="object-cover"
              />

              {/* Navigation arrows */}
              <button
                onClick={prevImage}
                className="absolute left-4 top-1/2 transform -translate-y-1/2 w-10 h-10 bg-white/80 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all hover:bg-white hover:scale-110"
              >
                <ChevronLeft className="w-5 h-5 text-graphite-800" />
              </button>
              <button
                onClick={nextImage}
                className="absolute right-4 top-1/2 transform -translate-y-1/2 w-10 h-10 bg-white/80 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-all hover:bg-white hover:scale-110"
              >
                <ChevronRight className="w-5 h-5 text-graphite-800" />
              </button>
            </div>

            {/* Thumbnail images */}
            <div className="grid grid-cols-4 gap-3">
              {product.images.map((image, index) => (
                <button
                  key={index}
                  onClick={() => setSelectedImageIndex(index)}
                  className={`relative aspect-square rounded-xl overflow-hidden transition-all ${
                    selectedImageIndex === index
                      ? 'ring-2 ring-primary scale-105'
                      : 'hover:scale-105 opacity-70 hover:opacity-100'
                  }`}
                >
                  <Image
                    src={image}
                    alt={`${product.name} ${index + 1}`}
                    fill
                    className="object-cover"
                  />
                </button>
              ))}
            </div>
          </div>

          {/* Product Info */}
          <div className="space-y-6">

            {/* Header */}
            <div>
              <div className="flex items-center justify-between mb-4">
                <span className="bg-amber-100 text-amber-800 px-3 py-1 rounded-full text-sm font-medium">
                  {product.category === 'COFFEE' ? 'Kawa Premium' : product.category === 'TEA' ? 'Herbata Premium' : 'Ilustracja'}
                </span>
                <button className="p-2 text-graphite-600 hover:text-danger hover:bg-warm-100 rounded-xl transition-all">
                  <Share2 className="w-5 h-5" />
                </button>
              </div>

              <h1 className="text-3xl md:text-4xl font-heading font-bold text-graphite-800 mb-4">
                {product.name}
              </h1>

              <p className="text-lg text-graphite-600 leading-relaxed">
                {product.description || 'Wysokiej jakości produkt'}
              </p>
            </div>



            {/* Price and donation */}
            <div className="bg-white/80 rounded-3xl p-6 shadow-soft">
              <div className="flex items-end justify-between mb-4">
                <div>
                  <span className="text-3xl font-bold text-primary">
                    {totalPrice.toFixed(2)} zł
                  </span>
                  {quantity > 1 && (
                    <span className="text-warm-600 ml-2">
                      ({product.price.toFixed(2)} zł/szt)
                    </span>
                  )}
                </div>
              </div>
            </div>

            {/* Quantity and Add to Cart */}
            <div className="space-y-4">
              <div className="flex items-center space-x-4">
                <label className="text-graphite-700 font-medium">Ilość:</label>
                <div className="flex items-center space-x-2">
                  <button
                    onClick={() => handleQuantityChange(quantity - 1)}
                    disabled={quantity <= 1}
                    className="w-10 h-10 bg-warm-200 rounded-xl flex items-center justify-center hover:bg-warm-300 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                  >
                    <Minus className="w-4 h-4" />
                  </button>
                  <span className="w-16 text-center font-medium text-lg">
                    {quantity}
                  </span>
                  <button
                    onClick={() => handleQuantityChange(quantity + 1)}
                    disabled={quantity >= 25}
                    className="w-10 h-10 bg-warm-200 rounded-xl flex items-center justify-center hover:bg-warm-300 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                  >
                    <Plus className="w-4 h-4" />
                  </button>
                </div>
                <span className="text-sm text-warm-600">
                  Dostępne: 25 szt
                </span>
              </div>

              <div className="flex flex-col sm:flex-row gap-4">
                <button
                  onClick={handleAddToCart}
                  className="btn-primary flex-1 text-lg py-4"
                >
                  <ShoppingBag className="w-5 h-5 mr-2" />
                  Dodaj do koszyka
                </button>
                <button className="btn-secondary py-4 px-6">
                  <Heart className="w-5 h-5" />
                </button>
              </div>
            </div>


          </div>
        </div>

        {/* Product Details Tabs */}
        <div className="bg-white/80 rounded-3xl shadow-soft">

          {/* Tab Headers */}
          <div className="flex border-b border-warm-200/50">
            {[
              { key: 'description', label: 'Opis' },
              { key: 'shipping', label: 'Dostawa i zwroty' }
            ].map((tab) => (
              <button
                key={tab.key}
                onClick={() => setSelectedTab(tab.key as any)}
                className={`px-6 py-4 font-medium transition-colors ${
                  selectedTab === tab.key
                    ? 'text-primary border-b-2 border-primary'
                    : 'text-graphite-600 hover:text-primary'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>

          {/* Tab Content */}
          <div className="p-8">

            {/* Description Tab */}
            {selectedTab === 'description' && (
              <div className="space-y-6">
                <div className="prose prose-lg max-w-none">
                  <p className="text-graphite-700 leading-relaxed whitespace-pre-line">
                    {product.description}
                  </p>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-6 mt-8">
                  <div className="bg-warm-100 rounded-2xl p-6">
                    <h4 className="font-heading font-bold text-graphite-800 mb-4">Specyfikacja</h4>
                    <ul className="space-y-2 text-sm text-graphite-700">
                      <li><span className="font-medium">Waga:</span> {product.details?.weight || '250g'}</li>
                      {product.details?.origin && <li><span className="font-medium">Pochodzenie:</span> {product.details.origin}</li>}
                      {product.details?.roastProfile && <li><span className="font-medium">Palenie:</span> {product.details.roastProfile}</li>}
                      {product.details?.variety && <li><span className="font-medium">Odmiana:</span> {product.details.variety}</li>}
                      {product.details?.processing && <li><span className="font-medium">Obróbka:</span> {product.details.processing}</li>}
                      {product.details?.region && <li><span className="font-medium">Region:</span> {product.details.region}</li>}
                      {product.details?.flavorProfile && <li><span className="font-medium">Profil smakowy:</span> {product.details.flavorProfile}</li>}
                      {product.details?.composition && <li><span className="font-medium">Skład:</span> {product.details.composition}</li>}
                    </ul>
                  </div>

{product.details?.idealFor && (
                    <div className="bg-blue-50 rounded-2xl p-6">
                      <h4 className="font-heading font-bold text-graphite-800 mb-4 flex items-center">
                        ☕ Sposób parzenia
                      </h4>
                      <p className="text-sm text-graphite-700 leading-relaxed">
                        {product.details.idealFor}
                      </p>
                    </div>
                  )}


                </div>
              </div>
            )}



            {/* Shipping Tab */}
            {selectedTab === 'shipping' && (
              <div className="space-y-6">
                <h3 className="text-2xl font-heading font-bold text-graphite-800">
                  Dostawa i zwroty
                </h3>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                  <div>
                    <h4 className="font-heading font-bold text-graphite-800 mb-4">Opcje dostawy</h4>
                    <div className="space-y-4">
                      <div className="flex justify-between items-center p-4 bg-warm-50 rounded-2xl">
                        <div>
                          <p className="font-medium">InPost Paczkomat</p>
                          <p className="text-sm text-warm-600">1-2 dni roboczych</p>
                        </div>
                        <span className="font-bold text-primary">8,99 zł</span>
                      </div>
                      <div className="flex justify-between items-center p-4 bg-warm-50 rounded-2xl">
                        <div>
                          <p className="font-medium">Kurier InPost</p>
                          <p className="text-sm text-warm-600">1-2 dni roboczych</p>
                        </div>
                        <span className="font-bold text-primary">12,99 zł</span>
                      </div>
                      <div className="flex justify-between items-center p-4 bg-success/10 rounded-2xl">
                        <div>
                          <p className="font-medium">Darmowa dostawa</p>
                          <p className="text-sm text-warm-600">przy zamówieniach od 99 zł</p>
                        </div>
                        <span className="font-bold text-success">0 zł</span>
                      </div>
                    </div>
                  </div>

                  <div>
                    <h4 className="font-heading font-bold text-graphite-800 mb-4">Zwroty i reklamacje</h4>
                    <ul className="space-y-3 text-sm text-graphite-700">
                      <li>✅ 30 dni na zwrot bez podania przyczyny</li>
                      <li>✅ Bezpłatny zwrot przy zamówieniach nad 99 zł</li>
                      <li>✅ Pełny zwrot kosztów przy produkcie wadliwym</li>
                      <li>✅ Możliwość wymiany na inny produkt</li>
                      <li>✅ Szybka realizacja - zwrot w 3-5 dni</li>
                    </ul>
                  </div>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>
  )
}
