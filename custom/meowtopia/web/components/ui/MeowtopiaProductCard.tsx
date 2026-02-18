'use client'

import { useState } from 'react'
import Link from 'next/link'
import { ShoppingCart, Star, Heart, Eye, Plus, Minus } from 'lucide-react'
import { useCartStore } from '@/lib/store/cart'

interface Product {
  id: string
  name: string
  price: number
  oldPrice?: number
  image: string
  rating: number
  reviews: number
  category: string
  inStock: boolean
  description: string
  featured?: boolean
  tags: string[]
}

interface ProductCardProps {
  product: Product
  onAddToCart: (productId: string) => void
}

export default function MeowtopiaProductCard({ product, onAddToCart }: ProductCardProps) {
  const [isHovered, setIsHovered] = useState(false)
  const addToCart = useCartStore(state => state.addItem)

  const handleAddToCart = () => {
    addToCart({
      id: product.id,
      name: product.name,
      price: product.price,
      image: product.image,
      category: product.category
    }, 1)
    onAddToCart(product.id)
  }

  const getCategoryColor = (category: string) => {
    switch (category.toLowerCase()) {
      case 'kawa':
        return 'text-meo-ginger bg-meo-ginger/10' // ginger for coffee
      case 'herbata':
        return 'text-meo-rescue bg-meo-rescue/10' // rescue green for tea
      case 'plakaty':
        return 'text-meo-rose bg-meo-rose/10' // rose for posters
      default:
        return 'text-meo-dark bg-meo-dark/10'
    }
  }

  const discountPercentage = product.oldPrice
    ? Math.round((1 - product.price / product.oldPrice) * 100)
    : 0

  return (
    <div
      className="bg-product-card rounded-3xl p-6 shadow-meo-soft hover:shadow-meo-medium transition-all duration-300 group relative"
      onMouseEnter={() => setIsHovered(true)}
      onMouseLeave={() => setIsHovered(false)}
    >
      {/* Discount Badge */}
      {discountPercentage > 0 && (
        <div className="absolute -top-2 -right-2 bg-meo-ginger text-white text-sm font-bold px-3 py-1 rounded-full z-10 shadow-meo-warm">
          -{discountPercentage}%
        </div>
      )}

      {/* Featured Badge */}
      {product.featured && (
        <div className="absolute top-4 left-4 bg-meo-dark text-meo-cream text-xs font-semibold px-2 py-1 rounded-full z-10 flex items-center gap-1 shadow-meo-soft">
          <Star className="w-3 h-3 fill-current" />
          POLECANE
        </div>
      )}

      {/* Product Image/Emoji */}
      <div className="text-center mb-6 relative">
        <div className="text-6xl mb-4 group-hover:scale-110 transition-transform duration-300 cursor-pointer">
          {product.image}
        </div>

        {/* Quick Actions - pokazują się na hover */}
        <div className={`absolute inset-0 flex items-center justify-center gap-2 transition-all duration-300 ${
          isHovered ? 'opacity-100' : 'opacity-0'
        }`}>
          <button className="p-2 bg-white/90 hover:bg-white text-meo-dark rounded-full shadow-lg hover:scale-110 transition-all">
            <Eye className="w-4 h-4" />
          </button>
          <button className="p-2 bg-white/90 hover:bg-white text-rose-500 rounded-full shadow-lg hover:scale-110 transition-all">
            <Heart className="w-4 h-4" />
          </button>
        </div>
      </div>

      {/* Product Info */}
      <div className="space-y-3">
        {/* Category */}
        <div className={`text-xs font-semibold uppercase tracking-wide px-2 py-1 rounded-full inline-block ${getCategoryColor(product.category)}`}>
          {product.category}
        </div>

        {/* Name */}
        <h3 className="text-xl font-semibold text-meo-dark group-hover:text-meo-ginger transition-colors line-clamp-2">
          {product.name}
        </h3>

        {/* Description */}
        <p className="text-meo-dark/70 text-sm leading-relaxed line-clamp-2">
          {product.description}
        </p>

        {/* Rating */}
        <div className="flex items-center gap-2">
          <div className="flex items-center">
            {[...Array(5)].map((_, i) => (
              <Star
                key={i}
                className={`w-4 h-4 ${
                  i < Math.floor(product.rating)
                    ? 'text-meo-ginger fill-current' // ginger for stars
                    : 'text-gray-300'
                }`}
              />
            ))}
          </div>
          <span className="text-sm text-meo-dark/60">
            {product.rating} ({product.reviews})
          </span>
        </div>

        {/* Tags */}
        <div className="flex flex-wrap gap-1">
          {product.tags.slice(0, 3).map((tag, index) => (
            <span
              key={index}
              className="text-xs bg-meo-beige/20 text-meo-dark px-2 py-1 rounded-full border border-meo-beige/30"
            >
              {tag}
            </span>
          ))}
          {product.tags.length > 3 && (
            <span className="text-xs text-meo-dark/50">
              +{product.tags.length - 3}
            </span>
          )}
        </div>
      </div>

      {/* Price & Actions */}
      <div className="flex items-center justify-between pt-6 mt-6 border-t border-meo-dark/10">
        <div className="flex items-center gap-2">
          {product.oldPrice && (
            <span className="text-meo-dark/50 line-through text-sm font-medium">
              {product.oldPrice.toFixed(2)} zł
            </span>
          )}
          <span className="text-2xl font-bold text-meo-dark">
            {product.price.toFixed(2)} zł
          </span>
        </div>

        {product.inStock ? (
          <button
            onClick={handleAddToCart}
            className="bg-meo-dark text-meo-cream px-6 py-2 rounded-full font-semibold hover:bg-meo-ginger hover:text-meo-dark transition-all duration-200 flex items-center gap-2 group/btn shadow-meo-soft"
          >
            <ShoppingCart className="w-4 h-4 group-hover/btn:scale-110 transition-transform" />
            Dodaj
          </button>
        ) : (
          <button
            disabled
            className="bg-gray-300 text-gray-500 px-6 py-2 rounded-full font-semibold cursor-not-allowed"
          >
            Brak w magazynie
          </button>
        )}
      </div>

      {/* Stock status indicator */}
      <div className="flex items-center justify-center mt-4">
        <div className={`w-2 h-2 rounded-full mr-2 ${product.inStock ? 'bg-green-500' : 'bg-red-500'}`}></div>
        <span className={`text-xs font-medium ${product.inStock ? 'text-meo-rescue' : 'text-meo-rose'}`}>
          {product.inStock ? 'Dostępny' : 'Niedostępny'}
        </span>
      </div>

      {/* Donation info */}
      <div className="mt-4 p-3 bg-meo-rescue/10 rounded-xl border border-meo-rescue/20">
        <div className="flex items-center gap-2 text-meo-rescue">
          <Heart className="w-4 h-4" />
          <span className="text-sm font-medium">
            {(product.price * 0.05).toFixed(2)} zł wspiera zwierzęta
          </span>
        </div>
      </div>
    </div>
  )
}

// Lista produktów component
interface ProductGridProps {
  products: Product[]
  onAddToCart: (productId: string) => void
}

export function MeowtopiaProductGrid({ products, onAddToCart }: ProductGridProps) {
  const [sortBy, setSortBy] = useState('featured')
  const [filterBy, setFilterBy] = useState('wszystkie')

  const filteredAndSortedProducts = products
    .filter(product => {
      if (filterBy === 'wszystkie') return true
      return product.category.toLowerCase() === filterBy.toLowerCase()
    })
    .sort((a, b) => {
      switch (sortBy) {
        case 'price-asc':
          return a.price - b.price
        case 'price-desc':
          return b.price - a.price
        case 'rating':
          return b.rating - a.rating
        case 'name':
          return a.name.localeCompare(b.name)
        default: // featured
          return (b.featured ? 1 : 0) - (a.featured ? 1 : 0)
      }
    })

  const categories = ['wszystkie', ...Array.from(new Set(products.map(p => p.category.toLowerCase())))]

  return (
    <div className="space-y-8">
      {/* Filters & Sort */}
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4 bg-white/80 backdrop-blur-sm rounded-2xl p-6">
        <div className="flex flex-wrap gap-2">
          {categories.map(category => (
            <button
              key={category}
              onClick={() => setFilterBy(category)}
              className={`px-4 py-2 rounded-full font-medium transition-all ${
                filterBy === category
                  ? 'bg-meo-warm text-white shadow-meo-warm'
                  : 'bg-gray-100 text-meo-dark hover:bg-meo-warm/10'
              }`}
            >
              {category.charAt(0).toUpperCase() + category.slice(1)}
            </button>
          ))}
        </div>

        <select
          value={sortBy}
          onChange={(e) => setSortBy(e.target.value)}
          className="px-4 py-2 bg-white border border-meo-warm/20 rounded-xl focus:outline-none focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20"
        >
          <option value="featured">Polecane</option>
          <option value="price-asc">Cena: od najniższej</option>
          <option value="price-desc">Cena: od najwyższej</option>
          <option value="rating">Najlepiej oceniane</option>
          <option value="name">Nazwa A-Z</option>
        </select>
      </div>

      {/* Products Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8">
        {filteredAndSortedProducts.map((product) => (
          <MeowtopiaProductCard
            key={product.id}
            product={product}
            onAddToCart={onAddToCart}
          />
        ))}
      </div>

      {filteredAndSortedProducts.length === 0 && (
        <div className="text-center py-12">
          <div className="text-6xl mb-4">😿</div>
          <h3 className="text-2xl font-bold text-meo-dark mb-2">
            Brak produktów
          </h3>
          <p className="text-meo-dark/70">
            Nie znaleźliśmy produktów w tej kategorii
          </p>
        </div>
      )}
    </div>
  )
}
