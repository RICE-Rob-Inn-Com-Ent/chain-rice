'use client'

import { useState, useEffect } from 'react'
import ProductCard from '@/components/ui/ProductCard'
import { Search, Filter, SlidersHorizontal, Grid, List } from 'lucide-react'

// Mock data - w przyszłości z bazy danych
const allProducts = [
  {
    id: '1',
    name: 'Mrucząca Arabica Premium',
    price: 34.99,
    category: 'COFFEE' as const,
    images: ['/placeholder-coffee1.jpg'],
    featured: true
  },
  {
    id: '2',
    name: 'Espresso Kot Na Drzewie',
    price: 29.99,
    category: 'COFFEE' as const,
    images: ['/placeholder-coffee2.jpg'],
    featured: false
  },
  {
    id: '3',
    name: 'Kawa Miaukowa Mieszanka',
    price: 27.99,
    category: 'COFFEE' as const,
    images: ['/placeholder-coffee3.jpg'],
    featured: false
  },
  // ŚWIĄTECZNE
  {
    id: '4',
    name: 'Grzaniec Galicyjski',
    price: 24.99,
    category: 'TEA' as const,
    images: ['/placeholder-tea1.jpg'],
    featured: true
  },
  {
    id: '5',
    name: 'Świąteczna',
    price: 22.99,
    category: 'TEA' as const,
    images: ['/placeholder-tea2.jpg'],
    featured: false
  },
  {
    id: '6',
    name: 'Zimowa Opowieść',
    price: 26.99,
    category: 'TEA' as const,
    images: ['/placeholder-tea3.jpg'],
    featured: false
  },
  {
    id: '10',
    name: 'Wigilijna Noc',
    price: 28.99,
    category: 'TEA' as const,
    images: ['/placeholder-tea4.jpg'],
    featured: true
  },
  // CZARNE po 100g
  {
    id: '11',
    name: 'Iberyjski Sen (100g)',
    price: 19.99,
    category: 'TEA' as const,
    images: ['/placeholder-tea5.jpg'],
    featured: false
  },
  {
    id: '12',
    name: 'Gruzińska (100g)',
    price: 21.99,
    category: 'TEA' as const,
    images: ['/placeholder-tea6.jpg'],
    featured: false
  },
  // ZIELONE po 100g
  {
    id: '13',
    name: 'Chwila Relaksu (100g)',
    price: 23.99,
    category: 'TEA' as const,
    images: ['/placeholder-tea7.jpg'],
    featured: false
  },
  {
    id: '14',
    name: 'Cytrynowa Sencha (100g)',
    price: 25.99,
    category: 'TEA' as const,
    images: ['/placeholder-tea8.jpg'],
    featured: false
  },
  // OWOCOWE po 100g
  {
    id: '15',
    name: 'Skarby Sadu (100g)',
    price: 20.99,
    category: 'TEA' as const,
    images: ['/placeholder-tea9.jpg'],
    featured: false
  },
  {
    id: '16',
    name: 'Owocowa Ekspresja (100g)',
    price: 22.99,
    category: 'TEA' as const,
    images: ['/placeholder-tea10.jpg'],
    featured: false
  },
  // BIAŁE po 50g
  {
    id: '17',
    name: 'Biała Róża (50g)',
    price: 35.99,
    category: 'TEA' as const,
    images: ['/placeholder-tea11.jpg'],
    featured: true
  },
  {
    id: '18',
    name: 'Słodkie Tropiki (50g)',
    price: 37.99,
    category: 'TEA' as const,
    images: ['/placeholder-tea12.jpg'],
    featured: false
  },
  {
    id: '7',
    name: 'Kot na Drzewie - Ilustracja A4',
    price: 29.99,
    category: 'ILLUSTRATION' as const,
    images: ['/placeholder-illustration1.jpg'],
    featured: true
  },
  {
    id: '8',
    name: 'Śpiący Kotek - Ilustracja A3',
    price: 39.99,
    category: 'ILLUSTRATION' as const,
    images: ['/placeholder-illustration2.jpg'],
    featured: false
  },
  {
    id: '9',
    name: 'Rodzina Kotów - Ilustracja A2',
    price: 49.99,
    category: 'ILLUSTRATION' as const,
    images: ['/placeholder-illustration3.jpg'],
    featured: false
  }
]

type SortOption = 'name-asc' | 'name-desc' | 'price-asc' | 'price-desc' | 'featured'
type CategoryFilter = 'ALL' | 'COFFEE' | 'TEA' | 'ILLUSTRATION'
type ViewMode = 'grid' | 'list'

export default function ProductsPage() {
  const [searchTerm, setSearchTerm] = useState('')
  const [categoryFilter, setCategoryFilter] = useState<CategoryFilter>('ALL')
  const [sortBy, setSortBy] = useState<SortOption>('featured')
  const [viewMode, setViewMode] = useState<ViewMode>('grid')
  const [showFilters, setShowFilters] = useState(false)

  // Filter and sort products
  const filteredProducts = allProducts
    .filter(product => {
      const matchesSearch = product.name.toLowerCase().includes(searchTerm.toLowerCase())
      const matchesCategory = categoryFilter === 'ALL' || product.category === categoryFilter
      return matchesSearch && matchesCategory
    })
    .sort((a, b) => {
      switch (sortBy) {
        case 'name-asc':
          return a.name.localeCompare(b.name)
        case 'name-desc':
          return b.name.localeCompare(a.name)
        case 'price-asc':
          return a.price - b.price
        case 'price-desc':
          return b.price - a.price
        case 'featured':
          return (b.featured ? 1 : 0) - (a.featured ? 1 : 0)
        default:
          return 0
      }
    })

  const totalDonation = filteredProducts.reduce((sum, product) => sum + (product.price * 0.05), 0)

  const categoryLabels = {
    ALL: 'Wszystkie',
    COFFEE: 'Kawy',
    TEA: 'Herbaty',
    ILLUSTRATION: 'Ilustracje'
  }

  return (
    <div className="min-h-screen bg-white">

      {/* Page Header */}
      <section className="bg-meo-grafit py-16">
        <div className="max-w-7xl mx-auto container-padding text-center text-white">
          <h1 className="text-4xl md:text-5xl font-heading font-bold mb-4">
            <span style={{ fontFamily: 'Poppins, serif', fontWeight: 900, color: 'white' }}>MeoWTopia</span> - produkty z misją 🛍️
          </h1>
          <p className="text-xl text-white/80 leading-relaxed max-w-2xl mx-auto">
            Każdy produkt to kawałek dobra. Wybierz ulubione i automatycznie wspieraj ratowanie zwierząt.
          </p>
        </div>
      </section>

      <div className="max-w-7xl mx-auto container-padding py-12">

        {/* Search and Filters */}
        <div className="bg-white border border-meo-grafit/10 rounded-lg p-6 mb-8 shadow-sm">
          <div className="flex flex-col lg:flex-row gap-4 items-center">

            {/* Search */}
            <div className="relative flex-1 w-full lg:max-w-md">
              <Search className="absolute left-4 top-1/2 transform -translate-y-1/2 text-meo-grafit/50 w-5 h-5" />
              <input
                type="text"
                placeholder="Szukaj produktów..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="input w-full pl-12"
              />
            </div>

            {/* Category Filter */}
            <div className="flex flex-wrap gap-2">
              {(Object.keys(categoryLabels) as CategoryFilter[]).map((category) => (
                <button
                  key={category}
                  onClick={() => setCategoryFilter(category)}
                  className={`px-4 py-2 rounded-lg font-medium transition-all ${
                    categoryFilter === category
                      ? 'bg-meo-rudy text-white'
                      : 'bg-meo-grafit/5 text-meo-grafit hover:bg-meo-grafit/10'
                  }`}
                >
                  {categoryLabels[category]}
                </button>
              ))}
            </div>

            {/* Filters Toggle */}
            <button
              onClick={() => setShowFilters(!showFilters)}
              className="lg:hidden p-2 text-meo-grafit hover:text-meo-rudy hover:bg-meo-grafit/5 rounded-lg transition-all"
            >
              <SlidersHorizontal className="w-5 h-5" />
            </button>
          </div>

          {/* Advanced Filters */}
          <div className={`mt-6 pt-6 border-t border-meo-grafit/10 flex-col lg:flex-row gap-4 items-center justify-between ${showFilters ? 'flex' : 'hidden lg:flex'}`}>
            {/* Sort */}
            <div className="flex items-center space-x-3">
              <label className="text-meo-grafit font-medium">Sortuj:</label>
              <select
                value={sortBy}
                onChange={(e) => setSortBy(e.target.value as SortOption)}
                className="input min-w-48"
              >
                <option value="featured">Polecane</option>
                <option value="name-asc">Nazwa A-Z</option>
                <option value="name-desc">Nazwa Z-A</option>
                <option value="price-asc">Cena rosnąco</option>
                <option value="price-desc">Cena malejąco</option>
              </select>
            </div>

            {/* View Mode */}
            <div className="flex items-center space-x-2">
              <button
                onClick={() => setViewMode('grid')}
                className={`p-2 rounded-lg transition-all ${
                  viewMode === 'grid'
                    ? 'bg-meo-zielony text-white'
                    : 'text-meo-grafit hover:bg-meo-grafit/5'
                }`}
              >
                <Grid className="w-5 h-5" />
              </button>
              <button
                onClick={() => setViewMode('list')}
                className={`p-2 rounded-lg transition-all ${
                  viewMode === 'list'
                    ? 'bg-meo-zielony text-white'
                    : 'text-meo-grafit hover:bg-meo-grafit/5'
                }`}
              >
                <List className="w-5 h-5" />
              </button>
            </div>
          </div>
        </div>

        {/* Results Summary */}
        <div className="flex flex-col md:flex-row justify-between items-center mb-8">
          <div>
            <p className="text-meo-grafit">
              Znaleziono <span className="font-bold">{filteredProducts.length}</span> produktów
              {categoryFilter !== 'ALL' && (
                <span className="text-meo-rudy"> w kategorii "{categoryLabels[categoryFilter]}"</span>
              )}
            </p>
          </div>

          {/* Donation Info */}
          {filteredProducts.length > 0 && (
            <div className="donation-badge">
              Razem na fundacje: {totalDonation.toFixed(2)} zł
            </div>
          )}
        </div>

        {/* Products Grid */}
        {filteredProducts.length > 0 ? (
          <div className={`grid gap-8 ${
            viewMode === 'grid'
              ? 'grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4'
              : 'grid-cols-1'
          }`}>
            {filteredProducts.map((product, index) => (
              <div
                key={product.id}
                className="animate-fade-in"
                style={{ animationDelay: `${index * 0.1}s` }}
              >
                <ProductCard product={product} />
              </div>
            ))}
          </div>
        ) : (
          <div className="text-center py-16">
            <div className="w-24 h-24 bg-meo-grafit/10 rounded-full flex items-center justify-center mx-auto mb-6">
              <Search className="w-12 h-12 text-meo-grafit/50" />
            </div>
            <h3 className="text-xl font-heading font-bold text-meo-grafit mb-4">
              Nie znaleźliśmy produktów
            </h3>
            <p className="text-meo-grafit/70 mb-8">
              Spróbuj zmienić filtry lub wyszukać inne frazy
            </p>
            <button
              onClick={() => {
                setSearchTerm('')
                setCategoryFilter('ALL')
                setSortBy('featured')
              }}
              className="btn-primary"
            >
              Wyczyść filtry
            </button>
          </div>
        )}

        {/* Load More (for future pagination) */}
        {filteredProducts.length > 0 && (
          <div className="text-center mt-12">
            <p className="text-meo-grafit/70 mb-6">
              Pokazano wszystkie dostępne produkty
            </p>
            <div className="bg-white border border-meo-grafit/10 rounded-lg p-6 max-w-md mx-auto shadow-sm">
              <p className="text-sm text-meo-grafit leading-relaxed">
                💡 <span className="font-semibold">Nie znajdziesz tego czego szukasz?</span><br />
                Napisz do nas! Regularnie dodajemy nowe produkty na podstawie Waszych sugestii.
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}
