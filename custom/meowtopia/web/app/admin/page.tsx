'use client'

import { useState } from 'react'
import Link from 'next/link'
import { Plus, Edit2, Trash2, Package, Users, Heart, DollarSign, Coffee, Eye } from 'lucide-react'
import { AddProductModal } from '../../components/admin/AddProductModal'
import { EditProductModal } from '../../components/admin/EditProductModal'

// Mock data - w prawdziwej aplikacji z bazy danych
const mockProducts = [
  {
    id: '1',
    name: 'Kawa Arabica Premium "Kocie Oko"',
    price: 34.99,
    oldPrice: 42.99,
    category: 'Kawa',
    inStock: true,
    featured: true,
    sales: 127
  },
  {
    id: '2',
    name: 'Herbata Earl Grey "Kocia Lady"',
    price: 18.99,
    oldPrice: 24.99,
    category: 'Herbata',
    inStock: true,
    featured: true,
    sales: 89
  },
  {
    id: '3',
    name: 'Plakat "Kawowy Kot" A3',
    price: 24.99,
    oldPrice: 29.99,
    category: 'Plakaty',
    inStock: true,
    featured: false,
    sales: 45
  }
]

const mockStats = {
  totalOrders: 1247,
  totalRevenue: 89340.50,
  donationAmount: 4467.03,
  activeProducts: 24
}

export default function AdminPanel() {
  const [activeTab, setActiveTab] = useState('dashboard')
  const [products, setProducts] = useState(mockProducts)
  const [showAddModal, setShowAddModal] = useState(false)
  const [showEditModal, setShowEditModal] = useState(false)
  const [editingProduct, setEditingProduct] = useState(null)

  const handleAddProduct = (newProduct: any) => {
    setProducts(prev => [...prev, newProduct])
  }

  const handleEditProduct = (product: any) => {
    setEditingProduct(product)
    setShowEditModal(true)
  }

  const handleSaveProduct = (updatedProduct: any) => {
    setProducts(prev => prev.map(p => p.id === updatedProduct.id ? updatedProduct : p))
  }

  const handleDeleteProduct = (productId: string) => {
    if (confirm('Czy na pewno chcesz usunąć ten produkt?')) {
      setProducts(prev => prev.filter(p => p.id !== productId))
    }
  }

  const tabs = [
    { id: 'dashboard', label: 'Dashboard', icon: Package },
    { id: 'products', label: 'Produkty', icon: Coffee },
    { id: 'orders', label: 'Zamówienia', icon: Users },
    { id: 'donations', label: 'Darowizny', icon: Heart }
  ]

  return (
    <div className="min-h-screen bg-gradient-to-br from-meo-cream via-cream-100 to-rose-50">
      <div className="flex h-screen">

        {/* Sidebar */}
        <div className="w-64 bg-meo-dark text-white p-6">
          <div className="mb-8">
            <h1 className="text-2xl font-display font-bold text-meo-warm">
              MeoWTopia Admin
            </h1>
            <p className="text-white/70 text-sm">Panel zarządzania sklepem</p>
          </div>

          <nav className="space-y-2">
            {tabs.map((tab) => {
              const Icon = tab.icon
              return (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-xl transition-colors ${
                    activeTab === tab.id
                      ? 'bg-meo-warm text-white'
                      : 'text-white/70 hover:text-white hover:bg-white/10'
                  }`}
                >
                  <Icon className="w-5 h-5" />
                  {tab.label}
                </button>
              )
            })}
          </nav>
        </div>

        {/* Main Content */}
        <div className="flex-1 p-8 overflow-auto">

          {/* Dashboard */}
          {activeTab === 'dashboard' && (
            <div className="space-y-8">
              <h2 className="text-3xl font-bold text-meo-dark">Dashboard</h2>

              {/* Stats Cards */}
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
                <div className="bg-white/90 backdrop-blur-sm rounded-2xl p-6 shadow-meo-soft">
                  <div className="flex items-center justify-between mb-4">
                    <DollarSign className="w-8 h-8 text-meo-warm" />
                    <span className="text-sm text-green-600 font-medium">+15%</span>
                  </div>
                  <h3 className="text-2xl font-bold text-meo-dark mb-2">
                    {mockStats.totalRevenue.toLocaleString('pl-PL')} zł
                  </h3>
                  <p className="text-meo-dark/70">Przychód (30 dni)</p>
                </div>

                <div className="bg-white/90 backdrop-blur-sm rounded-2xl p-6 shadow-meo-soft">
                  <div className="flex items-center justify-between mb-4">
                    <Package className="w-8 h-8 text-mint-500" />
                    <span className="text-sm text-green-600 font-medium">+8%</span>
                  </div>
                  <h3 className="text-2xl font-bold text-meo-dark mb-2">
                    {mockStats.totalOrders}
                  </h3>
                  <p className="text-meo-dark/70">Zamówienia</p>
                </div>

                <div className="bg-white/90 backdrop-blur-sm rounded-2xl p-6 shadow-meo-soft">
                  <div className="flex items-center justify-between mb-4">
                    <Heart className="w-8 h-8 text-rose-500" />
                    <span className="text-sm text-rose-600 font-medium heart-beat">♥</span>
                  </div>
                  <h3 className="text-2xl font-bold text-meo-dark mb-2">
                    {mockStats.donationAmount.toLocaleString('pl-PL')} zł
                  </h3>
                  <p className="text-meo-dark/70">Przekazane zwierzętom</p>
                </div>

                <div className="bg-white/90 backdrop-blur-sm rounded-2xl p-6 shadow-meo-soft">
                  <div className="flex items-center justify-between mb-4">
                    <Coffee className="w-8 h-8 text-lavender-500" />
                    <span className="text-sm text-blue-600 font-medium">24</span>
                  </div>
                  <h3 className="text-2xl font-bold text-meo-dark mb-2">
                    {mockStats.activeProducts}
                  </h3>
                  <p className="text-meo-dark/70">Aktywne produkty</p>
                </div>
              </div>

              {/* Recent Activity */}
              <div className="bg-white/90 backdrop-blur-sm rounded-2xl p-6 shadow-meo-soft">
                <h3 className="text-xl font-bold text-meo-dark mb-6">Ostatnia aktywność</h3>
                <div className="space-y-4">
                  <div className="flex items-center gap-4 p-4 bg-meo-cream rounded-xl">
                    <div className="w-2 h-2 bg-green-500 rounded-full"></div>
                    <span className="flex-1">Nowe zamówienie #1247 - Kawa Arabica Premium</span>
                    <span className="text-sm text-meo-dark/60">2 min temu</span>
                  </div>
                  <div className="flex items-center gap-4 p-4 bg-rose-50 rounded-xl">
                    <div className="w-2 h-2 bg-rose-500 rounded-full"></div>
                    <span className="flex-1">Przekazano 45.50 zł dla Schroniska "Kocie Serce"</span>
                    <span className="text-sm text-meo-dark/60">5 min temu</span>
                  </div>
                  <div className="flex items-center gap-4 p-4 bg-mint-50 rounded-xl">
                    <div className="w-2 h-2 bg-mint-500 rounded-full"></div>
                    <span className="flex-1">Dodano nowy produkt: Herbata Rumiankowa "Sen Kotka"</span>
                    <span className="text-sm text-meo-dark/60">1 godz temu</span>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Products Management */}
          {activeTab === 'products' && (
            <div className="space-y-8">
              <div className="flex justify-between items-center">
                <h2 className="text-3xl font-bold text-meo-dark">Zarządzanie produktami</h2>
                <button
                  onClick={() => setShowAddModal(true)}
                  className="btn-meo flex items-center gap-2"
                >
                  <Plus className="w-4 h-4" />
                  Dodaj produkt
                </button>
              </div>

              <div className="bg-white/90 backdrop-blur-sm rounded-2xl shadow-meo-soft overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full">
                    <thead className="bg-meo-warm/10 border-b border-meo-warm/20">
                      <tr>
                        <th className="text-left p-4 font-semibold text-meo-dark">Produkt</th>
                        <th className="text-left p-4 font-semibold text-meo-dark">Kategoria</th>
                        <th className="text-left p-4 font-semibold text-meo-dark">Cena</th>
                        <th className="text-left p-4 font-semibold text-meo-dark">Status</th>
                        <th className="text-left p-4 font-semibold text-meo-dark">Sprzedaż</th>
                        <th className="text-left p-4 font-semibold text-meo-dark">Akcje</th>
                      </tr>
                    </thead>
                    <tbody>
                      {products.map((product) => (
                        <tr key={product.id} className="border-b border-meo-dark/10 hover:bg-meo-warm/5">
                          <td className="p-4">
                            <div className="flex items-center gap-3">
                              <div className="text-2xl">☕</div>
                              <div>
                                <div className="font-medium text-meo-dark">{product.name}</div>
                                {product.featured && (
                                  <span className="text-xs bg-meo-warm text-white px-2 py-1 rounded-full">
                                    Polecane
                                  </span>
                                )}
                              </div>
                            </div>
                          </td>
                          <td className="p-4">
                            <span className={`px-3 py-1 rounded-full text-xs font-medium ${
                              product.category === 'Kawa' ? 'bg-meo-warm/10 text-meo-warm' :
                              product.category === 'Herbata' ? 'bg-mint-500/10 text-mint-500' :
                              'bg-lavender-500/10 text-lavender-500'
                            }`}>
                              {product.category}
                            </span>
                          </td>
                          <td className="p-4">
                            <div className="font-bold text-meo-dark">{product.price} zł</div>
                            {product.oldPrice && (
                              <div className="text-sm text-meo-dark/50 line-through">
                                {product.oldPrice} zł
                              </div>
                            )}
                          </td>
                          <td className="p-4">
                            <span className={`flex items-center gap-2 ${
                              product.inStock ? 'text-green-600' : 'text-red-600'
                            }`}>
                              <div className={`w-2 h-2 rounded-full ${
                                product.inStock ? 'bg-green-500' : 'bg-red-500'
                              }`}></div>
                              {product.inStock ? 'Dostępny' : 'Niedostępny'}
                            </span>
                          </td>
                          <td className="p-4 font-medium">{product.sales}</td>
                          <td className="p-4">
                            <div className="flex items-center gap-2">
                              <button className="p-2 text-meo-dark hover:text-meo-warm hover:bg-meo-warm/10 rounded-lg transition-colors">
                                <Eye className="w-4 h-4" />
                              </button>
                              <button
                                onClick={() => handleEditProduct(product)}
                                className="p-2 text-meo-dark hover:text-meo-warm hover:bg-meo-warm/10 rounded-lg transition-colors"
                              >
                                <Edit2 className="w-4 h-4" />
                              </button>
                              <button
                                onClick={() => handleDeleteProduct(product.id)}
                                className="p-2 text-red-500 hover:text-red-700 hover:bg-red-50 rounded-lg transition-colors"
                              >
                                <Trash2 className="w-4 h-4" />
                              </button>
                            </div>
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}

          {/* Other tabs placeholder */}
          {(activeTab === 'orders' || activeTab === 'donations') && (
            <div className="text-center py-20">
              <div className="text-6xl mb-4">🚧</div>
              <h2 className="text-2xl font-bold text-meo-dark mb-4">
                {activeTab === 'orders' ? 'Zarządzanie zamówieniami' : 'Zarządzanie darowiznamai'}
              </h2>
              <p className="text-meo-dark/70">
                Ta sekcja będzie dostępna w przyszłej wersji
              </p>
            </div>
          )}

        </div>
      </div>

      {/* Add Product Modal */}
      <AddProductModal
        isOpen={showAddModal}
        onClose={() => setShowAddModal(false)}
        onAdd={handleAddProduct}
      />

      {/* Edit Product Modal */}
      <EditProductModal
        isOpen={showEditModal}
        onClose={() => setShowEditModal(false)}
        onSave={handleSaveProduct}
        product={editingProduct}
      />
    </div>
  )
}
