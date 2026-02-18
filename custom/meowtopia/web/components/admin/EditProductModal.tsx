'use client'

import { useState, useEffect } from 'react'
import { X, Upload, Tag, Package, Coffee, Image, DollarSign, Save } from 'lucide-react'

interface EditProductModalProps {
  isOpen: boolean
  onClose: () => void
  onSave: (product: any) => void
  product: any
}

export function EditProductModal({ isOpen, onClose, onSave, product }: EditProductModalProps) {
  const [formData, setFormData] = useState({
    name: '',
    description: '',
    price: '',
    oldPrice: '',
    category: 'Kawa',
    image: '',
    featured: false,
    inStock: true
  })

  const [dragOver, setDragOver] = useState(false)

  useEffect(() => {
    if (product && isOpen) {
      setFormData({
        name: product.name || '',
        description: product.description || '',
        price: product.price?.toString() || '',
        oldPrice: product.oldPrice?.toString() || '',
        category: product.category || 'Kawa',
        image: product.image || '',
        featured: product.featured || false,
        inStock: product.inStock !== false
      })
    }
  }, [product, isOpen])

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    
    const updatedProduct = {
      ...product,
      name: formData.name,
      description: formData.description,
      price: parseFloat(formData.price),
      oldPrice: formData.oldPrice ? parseFloat(formData.oldPrice) : null,
      category: formData.category,
      image: formData.image || '/images/default-product.jpg',
      featured: formData.featured,
      inStock: formData.inStock
    }

    onSave(updatedProduct)
    onClose()
  }

  const handleImageDrop = (e: React.DragEvent) => {
    e.preventDefault()
    setDragOver(false)
    
    const files = e.dataTransfer.files
    if (files.length > 0) {
      const file = files[0]
      if (file.type.startsWith('image/')) {
        const imageUrl = URL.createObjectURL(file)
        setFormData(prev => ({ ...prev, image: imageUrl }))
      }
    }
  }

  const handleInputChange = (e: React.ChangeEvent<HTMLInputElement | HTMLSelectElement | HTMLTextAreaElement>) => {
    const { name, value, type } = e.target
    
    if (type === 'checkbox') {
      const checked = (e.target as HTMLInputElement).checked
      setFormData(prev => ({ ...prev, [name]: checked }))
    } else {
      setFormData(prev => ({ ...prev, [name]: value }))
    }
  }

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div className="bg-white rounded-2xl shadow-2xl w-full max-w-2xl max-h-[90vh] overflow-y-auto">
        
        {/* Header */}
        <div className="flex items-center justify-between p-6 border-b border-meo-dark/10">
          <h2 className="text-2xl font-bold text-meo-dark flex items-center gap-2">
            <Package className="w-6 h-6 text-meo-warm" />
            Edytuj produkt
          </h2>
          <button
            onClick={onClose}
            className="p-2 hover:bg-meo-dark/10 rounded-xl transition-colors"
          >
            <X className="w-5 h-5 text-meo-dark" />
          </button>
        </div>

        {/* Form */}
        <form onSubmit={handleSubmit} className="p-6 space-y-6">
          
          {/* Product Image */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-meo-dark">
              <Image className="w-4 h-4 inline mr-2" />
              Zdjęcie produktu
            </label>
            
            <div
              className={`border-2 border-dashed rounded-xl p-8 text-center transition-all ${
                dragOver 
                  ? 'border-meo-warm bg-meo-warm/5' 
                  : 'border-meo-dark/20 hover:border-meo-warm/50'
              }`}
              onDragOver={(e) => { e.preventDefault(); setDragOver(true) }}
              onDragLeave={() => setDragOver(false)}
              onDrop={handleImageDrop}
            >
              {formData.image ? (
                <div className="relative">
                  <img 
                    src={formData.image} 
                    alt="Preview" 
                    className="w-32 h-32 object-cover rounded-xl mx-auto"
                  />
                  <button
                    type="button"
                    onClick={() => setFormData(prev => ({ ...prev, image: '' }))}
                    className="absolute -top-2 -right-2 bg-red-500 text-white rounded-full p-1 hover:bg-red-600"
                  >
                    <X className="w-3 h-3" />
                  </button>
                </div>
              ) : (
                <div>
                  <Upload className="w-12 h-12 text-meo-dark/40 mx-auto mb-4" />
                  <p className="text-meo-dark/60">
                    Przeciągnij zdjęcie tutaj lub kliknij aby wybrać
                  </p>
                  <input
                    type="file"
                    accept="image/*"
                    className="hidden"
                    onChange={(e) => {
                      const file = e.target.files?.[0]
                      if (file) {
                        const imageUrl = URL.createObjectURL(file)
                        setFormData(prev => ({ ...prev, image: imageUrl }))
                      }
                    }}
                  />
                </div>
              )}
            </div>
          </div>

          {/* Product Name */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-meo-dark">
              Nazwa produktu *
            </label>
            <input
              type="text"
              name="name"
              value={formData.name}
              onChange={handleInputChange}
              required
              className="w-full px-4 py-3 rounded-xl border border-meo-dark/20 focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20 transition-all"
              placeholder='np. "Kawa Arabica Premium Kocie Oko"'
            />
          </div>

          {/* Description */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-meo-dark">
              Opis produktu
            </label>
            <textarea
              name="description"
              value={formData.description}
              onChange={handleInputChange}
              rows={3}
              className="w-full px-4 py-3 rounded-xl border border-meo-dark/20 focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20 transition-all resize-none"
              placeholder="Opisz produkt, jego zalety i pochodzenie..."
            />
          </div>

          {/* Price and Old Price */}
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <label className="block text-sm font-medium text-meo-dark">
                <DollarSign className="w-4 h-4 inline mr-1" />
                Cena aktualna (zł) *
              </label>
              <input
                type="number"
                name="price"
                value={formData.price}
                onChange={handleInputChange}
                step="0.01"
                min="0"
                required
                className="w-full px-4 py-3 rounded-xl border border-meo-dark/20 focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20 transition-all"
                placeholder="0.00"
              />
            </div>
            
            <div className="space-y-2">
              <label className="block text-sm font-medium text-meo-dark">
                Cena przed promocją (zł)
              </label>
              <input
                type="number"
                name="oldPrice"
                value={formData.oldPrice}
                onChange={handleInputChange}
                step="0.01"
                min="0"
                className="w-full px-4 py-3 rounded-xl border border-meo-dark/20 focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20 transition-all"
                placeholder="0.00"
              />
            </div>
          </div>

          {/* Category */}
          <div className="space-y-2">
            <label className="block text-sm font-medium text-meo-dark">
              <Tag className="w-4 h-4 inline mr-2" />
              Kategoria *
            </label>
            <select
              name="category"
              value={formData.category}
              onChange={handleInputChange}
              required
              className="w-full px-4 py-3 rounded-xl border border-meo-dark/20 focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20 transition-all"
            >
              <option value="Kawa">☕ Kawa</option>
              <option value="Herbata">🍃 Herbata</option>
              <option value="Plakaty">🖼️ Plakaty</option>
              <option value="Akcesoria">🎁 Akcesoria</option>
            </select>
          </div>

          {/* Options */}
          <div className="space-y-4">
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                name="featured"
                id="featured"
                checked={formData.featured}
                onChange={handleInputChange}
                className="w-5 h-5 text-meo-warm rounded focus:ring-meo-warm"
              />
              <label htmlFor="featured" className="text-sm text-meo-dark">
                Produkt polecany (wyświetl na stronie głównej)
              </label>
            </div>
            
            <div className="flex items-center gap-3">
              <input
                type="checkbox"
                name="inStock"
                id="inStock"
                checked={formData.inStock}
                onChange={handleInputChange}
                className="w-5 h-5 text-meo-warm rounded focus:ring-meo-warm"
              />
              <label htmlFor="inStock" className="text-sm text-meo-dark">
                Produkt dostępny w magazynie
              </label>
            </div>
          </div>

          {/* Buttons */}
          <div className="flex gap-4 pt-6">
            <button
              type="button"
              onClick={onClose}
              className="flex-1 px-6 py-3 border border-meo-dark/20 text-meo-dark rounded-xl hover:bg-meo-dark/5 transition-colors"
            >
              Anuluj
            </button>
            <button
              type="submit"
              className="flex-1 btn-meo flex items-center justify-center gap-2"
            >
              <Save className="w-4 h-4" />
              Zapisz zmiany
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}