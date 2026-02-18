'use client'

import { useEffect, useState } from 'react'
import Link from 'next/link'
import Image from 'next/image'
import { Icon } from '@iconify/react'
import { Heart } from 'lucide-react'
import { useCartStore } from '@/lib/store/cart'
import { InpostPickupModal, InpostPointSummary } from '@/lib/inpost/InpostPickupModal'
import { OrlenPickupModal, OrlenPointSummary } from '@/lib/orlen/OrlenPickupModal'

export default function CartPageNew() {
  const { items, addItem, removeItem, updateQuantity, clearCart, getTotalPrice, getTotalItems } =
    useCartStore()
  const [promoCode, setPromoCode] = useState('')
  const [customerData, setCustomerData] = useState({
    firstName: '',
    lastName: '',
    email: '',
    phone: '',
    notes: ''
  })
  const [isPaying, setIsPaying] = useState(false)
  const [paymentError, setPaymentError] = useState<string | null>(null)
  const [shippingMethod, setShippingMethod] = useState('')
  const [freeShippingThreshold, setFreeShippingThreshold] = useState<number>(199)
  const [selectedInpostPoint, setSelectedInpostPoint] = useState<InpostPointSummary | null>(null)
  const [isInpostModalOpen, setIsInpostModalOpen] = useState(false)
  const [selectedOrlenPoint, setSelectedOrlenPoint] = useState<OrlenPointSummary | null>(null)
  const [isOrlenModalOpen, setIsOrlenModalOpen] = useState(false)

  const subtotal = getTotalPrice()
  const donationAmount = subtotal * 0.05

  const isFreeShipping = subtotal >= freeShippingThreshold
  const hasSelectedShipping = !!shippingMethod
  const requiresPickupPoint = shippingMethod === 'inpost' || shippingMethod === 'orlen'
  const hasPickupPoint =
    shippingMethod === 'inpost'
      ? !!selectedInpostPoint
      : shippingMethod === 'orlen'
        ? !!selectedOrlenPoint
        : true
  const canCheckout = hasSelectedShipping && (!requiresPickupPoint || hasPickupPoint)
  const baseShippingCost = !hasSelectedShipping
    ? 0
    : shippingMethod === 'personal'
      ? 0
      : shippingMethod === 'orlen'
        ? 11.99
        : 12.99
  const shippingCost = !hasSelectedShipping || isFreeShipping ? 0 : baseShippingCost
  // Kwota do zapłaty: tylko produkty + dostawa (darowizna 5% jest z tej kwoty, ale nie jest doliczana ekstra)
  const total = subtotal + shippingCost

  // Pobierz aktualny próg darmowej dostawy z API (jeśli skonfigurowany w panelu)
  useEffect(() => {
    const fetchSettings = async () => {
      try {
        const res = await fetch('/api/store-settings')
        if (res.ok) {
          const data = await res.json()
          if (typeof data.freeShippingThreshold === 'number') {
            setFreeShippingThreshold(data.freeShippingThreshold)
          }
        }
      } catch (error) {
        console.error('Error loading store settings', error)
      }
    }

    fetchSettings()
  }, [])

  // Pobierz dane zalogowanego użytkownika i wypełnij formularz
  useEffect(() => {
    const fetchCustomerData = async () => {
      try {
        const res = await fetch('/api/customer/profile')
        if (res.ok) {
          const data = await res.json()
          if (data.ok && data.customer) {
            setCustomerData(prev => ({
              ...prev,
              firstName: data.customer.firstName || prev.firstName,
              lastName: data.customer.lastName || prev.lastName,
              email: data.customer.email || prev.email,
              phone: data.customer.phone || prev.phone
            }))
          }
        }
        // Jeśli użytkownik nie jest zalogowany (401), po prostu nie wypełniamy formularza
      } catch (error) {
        console.error('Error loading customer data', error)
      }
    }

    fetchCustomerData()
  }, [])

  const shippingOptions = [
    {
      id: 'inpost',
      name: 'InPost Paczkomaty',
      basePrice: 12.99,
      time: '1-2 dni robocze',
      logoSrc: '/shipping-inpost.svg',
      logoAlt: 'InPost Paczkomaty'
    },
    {
      id: 'orlen',
      name: 'Orlen Paczka',
      basePrice: 11.99,
      time: '1-2 dni robocze',
      logoSrc: '/shipping-orlen.svg',
      logoAlt: 'Orlen Paczka'
    },
    {
      id: 'personal',
      name: 'Odbiór osobisty',
      basePrice: 0,
      time: 'ul. Kocia 12, Warszawa',
      logoSrc: '/shipping-personal.svg',
      logoAlt: 'Odbiór osobisty'
    }
  ]

  const handleCustomerChange = (
    e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement>
  ) => {
    const { name, value } = e.target
    setCustomerData(prev => ({
      ...prev,
      [name]: value
    }))
  }

  const canSubmitOrder =
    canCheckout &&
    customerData.firstName.trim() &&
    customerData.lastName.trim() &&
    customerData.email.trim() &&
    customerData.phone.trim()

  const handlePay = async () => {
    if (!canSubmitOrder || isPaying) return

    setIsPaying(true)
    setPaymentError(null)

    try {
      const res = await fetch('/api/payments/przelewy24', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          items,
          subtotal,
          shippingCost,
          total,
          donationAmount,
          shippingMethod,
          inpostPoint: selectedInpostPoint,
          orlenPoint: selectedOrlenPoint,
          customer: customerData,
          promoCode: promoCode || null
        })
      })

      const payload = await res.json().catch(() => null)

      if (!res.ok || !payload?.ok || !payload?.redirectUrl) {
        console.error('Przelewy24 init error', payload ?? res.statusText)
        setPaymentError(
          payload?.error ||
            'Nie udało się zainicjować płatności w Przelewy24. Spróbuj ponownie później.'
        )
        return
      }

      // Prawdziwy redirect do bramki płatniczej Przelewy24
      window.location.href = payload.redirectUrl
    } catch (err) {
      console.error('Przelewy24 request failed', err)
      setPaymentError('Wystąpił błąd połączenia z Przelewy24. Spróbuj ponownie później.')
    } finally {
      setIsPaying(false)
    }
  }

  const handleInpostRedirect = async () => {
    try {
      const res = await fetch('/api/inpost/redirect')
      const payload = await res.json().catch(() => null)

      if (!res.ok || !payload?.ok || !payload?.redirectUrl) {
        console.error('InPost redirect error', payload ?? res.statusText)
        return
      }

      window.location.href = payload.redirectUrl
    } catch (err) {
      console.error('InPost redirect request failed', err)
    }
  }

  if (items.length === 0) {
    return (
      <div className="min-h-screen bg-gradient-to-br from-meo-cream via-cream-100 to-rose-50 py-20 px-4">
        <div className="max-w-4xl mx-auto text-center">
          <div className="text-8xl mb-8">🛒</div>
          <h1 className="text-4xl font-display font-bold text-meo-dark mb-6">
            Twój koszyk jest pusty
          </h1>
          <p className="text-xl text-meo-dark/70 mb-8">
            Czas dodać trochę kawy, herbaty lub pięknych plakatów z kotami!
          </p>
          <Link 
            href="/"
            className="bg-meo-warm text-white px-8 py-4 rounded-full font-semibold text-lg shadow-meo-warm hover:bg-cream-700 transition-all duration-300 inline-flex items-center gap-2 group"
          >
            <Icon icon="material-symbols:shopping-cart" className="w-5 h-5 rounded" />
            Rozpocznij zakupy
            <Icon icon="material-symbols:arrow-forward" className="w-5 h-5 group-hover:translate-x-1 transition-transform rounded" />
          </Link>
        </div>
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-gradient-to-br from-meo-cream via-cream-100 to-rose-50 py-20 px-4">
      <div className="max-w-7xl mx-auto">
        <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
          {/* Cart Items + Shipping Options */}
          <div className="lg:col-span-2 space-y-4">
            {items.map((item) => (
              <div key={item.id} className="bg-white/80 backdrop-blur-sm rounded-2xl p-6 shadow-meo-soft">
                <div className="flex items-center gap-6">
                  {/* Product Image */}
                  <div className="relative w-24 h-24 rounded-xl overflow-hidden bg-gray-100 flex-shrink-0">
                    <Image
                      src={item.image || '/placeholder-product.jpg'}
                      alt={item.name}
                      fill
                      className="object-cover"
                      sizes="96px"
                    />
                  </div>
                  
                  {/* Product Details */}
                  <div className="flex-1">
                    <h3 className="text-lg font-semibold text-meo-dark mb-1">{item.name}</h3>
                    <div className="text-meo-dark/60 text-sm mb-2">
                      Jednostka: {item.price.toFixed(2)} zł
                    </div>
                    <div className="flex items-center gap-2 text-xs text-rose-600">
                      <Icon icon="material-symbols:favorite" className="w-3 h-3 rounded" />
                      <span>{(item.price * item.quantity * 0.05).toFixed(2)} zł z tego produktu trafi na cele charytatywne</span>
                    </div>
                  </div>
                  
                  {/* Quantity Controls */}
                  <div className="flex items-center gap-3">
                    <button
                      onClick={() => updateQuantity(item.id, Math.max(0, item.quantity - 1))}
                      className="w-8 h-8 bg-meo-warm/10 hover:bg-meo-warm/20 text-meo-warm rounded-full flex items-center justify-center transition-colors"
                    >
                      <Icon icon="material-symbols:remove" className="w-4 h-4 rounded" />
                    </button>
                    <span className="w-8 text-center font-semibold text-meo-dark">
                      {item.quantity}
                    </span>
                    <button
                      onClick={() => updateQuantity(item.id, item.quantity + 1)}
                      className="w-8 h-8 bg-meo-warm/10 hover:bg-meo-warm/20 text-meo-warm rounded-full flex items-center justify-center transition-colors"
                    >
                      <Icon icon="material-symbols:add" className="w-4 h-4 rounded" />
                    </button>
                  </div>
                  
                  {/* Item Total */}
                  <div className="text-right">
                    <div className="text-xl font-bold text-meo-dark">
                      {(item.price * item.quantity).toFixed(2)} zł
                    </div>
                    <button
                      onClick={() => removeItem(item.id)}
                      className="text-red-500 hover:text-red-700 text-sm mt-1 transition-colors flex items-center gap-1"
                    >
                      <Icon icon="material-symbols:close" className="w-3 h-3 rounded" />
                      Usuń
                    </button>
                  </div>
                </div>
              </div>
            ))}
            
            {/* Actions */}
            <div className="flex justify-between items-center pt-6">
              <button
                onClick={clearCart}
                className="text-red-500 hover:text-red-700 font-semibold transition-colors"
              >
                Wyczyść koszyk
              </button>
              <Link
                href="/"
                className="text-meo-warm hover:text-cream-700 font-semibold transition-colors flex items-center gap-2"
              >
                <Icon icon="material-symbols:arrow-back" className="w-4 h-4 rounded" />
                Kontynuuj zakupy
              </Link>
            </div>

            {/* Shipping Options */}
            <div className="bg-white/90 backdrop-blur-sm rounded-2xl p-6 shadow-meo-medium">
              <h3 className="text-lg font-bold text-meo-dark mb-1 flex items-center gap-2">
                <Icon icon="material-symbols:local-shipping" className="w-5 h-5 rounded" />
                Opcje dostawy
              </h3>
              <p className="text-xs text-meo-dark/60 mb-4">
                Darmowa dostawa od {freeShippingThreshold.toFixed(2)} zł (oprócz odbioru osobistego, który zawsze jest gratis).
              </p>
              
              <div className="space-y-3">
                {shippingOptions.map((option) => {
                  const isPickup = option.id === 'personal'
                  const effectivePrice = isFreeShipping && !isPickup ? 0 : option.basePrice

                  return (
                    <label
                      key={option.id}
                      className={`flex items-center gap-3 p-3 rounded-xl cursor-pointer transition-all ${
                        shippingMethod === option.id
                          ? 'bg-meo-warm/10 border-2 border-meo-warm'
                          : 'bg-gray-50 border-2 border-transparent hover:bg-meo-warm/5'
                        }`}
                    >
                      <input
                        type="radio"
                        name="shipping"
                        value={option.id}
                        checked={shippingMethod === option.id}
                        onChange={(e) => {
                          const id = e.target.value
                          setShippingMethod(id)

                          if (id === 'inpost') {
                            // Zamiast otwierać tylko modal, przekieruj do sandbox API InPost (INPOST_API_URL)
                            handleInpostRedirect()
                          } else if (id === 'orlen') {
                            setIsOrlenModalOpen(true)
                          } else {
                            // Zmiana metody dostawy czyści wybrane punkty
                            setSelectedInpostPoint(null)
                            setSelectedOrlenPoint(null)
                          }
                        }}
                        className="sr-only"
                      />
                      <div className="relative w-9 h-9 flex-shrink-0 rounded-lg overflow-hidden bg-white">
                        <Image
                          src={option.logoSrc}
                          alt={option.logoAlt}
                          fill
                          className="object-contain"
                          sizes="36px"
                        />
                      </div>
                      <div className="flex-1">
                        <div className="font-semibold text-meo-dark">{option.name}</div>
                        <div className="text-sm text-meo-dark/60">{option.time}</div>
                        {option.id === 'inpost' && selectedInpostPoint && (
                          <div className="mt-1 text-xs text-meo-dark/70">
                            Wybrany paczkomat:
                            <span className="font-semibold"> {selectedInpostPoint.name}</span>
                            <br />
                            <span>{selectedInpostPoint.address}</span>
                            <button
                              type="button"
                              className="ml-1 text-meo-warm underline hover:no-underline"
                              onClick={(event) => {
                                event.preventDefault()
                                event.stopPropagation()
                                setIsInpostModalOpen(true)
                              }}
                            >
                              Zmień paczkomat
                            </button>
                          </div>
                        )}
                        {option.id === 'orlen' && (
                          <div className="mt-1 text-xs text-meo-dark/70">
                            {selectedOrlenPoint ? (
                              <>
                                Wybrany punkt Orlen Paczka:
                                <span className="font-semibold"> {selectedOrlenPoint.name}</span>
                                <br />
                                <span>{selectedOrlenPoint.address}</span>
                                <button
                                  type="button"
                                  className="ml-1 text-meo-warm underline hover:no-underline"
                                  onClick={(event) => {
                                    event.preventDefault()
                                    event.stopPropagation()
                                    setIsOrlenModalOpen(true)
                                  }}
                                >
                                  Zmień punkt
                                </button>
                              </>
                            ) : (
                              <>
                                Nie wybrano jeszcze punktu Orlen Paczka.
                                {shippingMethod === 'orlen' && (
                                  <button
                                    type="button"
                                    className="ml-1 text-meo-warm underline hover:no-underline"
                                    onClick={(event) => {
                                      event.preventDefault()
                                      event.stopPropagation()
                                      setIsOrlenModalOpen(true)
                                    }}
                                  >
                                    Wybierz punkt
                                  </button>
                                )}
                              </>
                            )}
                          </div>
                        )}
                      </div>
                      <div className="text-right">
                        <div className="font-bold text-meo-dark">
                          {effectivePrice === 0 ? 'Gratis' : `${effectivePrice.toFixed(2)} zł`}
                        </div>
                        {isFreeShipping && !isPickup && option.basePrice > 0 && (
                          <div className="text-[10px] text-meo-dark/50">
                            (standardowo {option.basePrice.toFixed(2)} zł)
                          </div>
                        )}
                      </div>
                    </label>
                  )
                })}
              </div>
            </div>
          </div>

          {/* Order Summary */}
          <div className="space-y-6">
            {/* Customer Data + Summary Card */}
            <div className="bg-white/90 backdrop-blur-sm rounded-2xl p-6 shadow-meo-medium">
              <h3 className="text-xl font-bold text-meo-dark mb-4">Dane do zamówienia</h3>

              {/* Customer Form */}
              <div className="space-y-3 mb-6">
                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-sm font-medium text-meo-dark mb-1">
                      Imię *
                    </label>
                    <input
                      type="text"
                      name="firstName"
                      value={customerData.firstName}
                      onChange={handleCustomerChange}
                      className="w-full px-3 py-2 border border-meo-warm/20 rounded-xl focus:outline-none focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20 text-sm"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-meo-dark mb-1">
                      Nazwisko *
                    </label>
                    <input
                      type="text"
                      name="lastName"
                      value={customerData.lastName}
                      onChange={handleCustomerChange}
                      className="w-full px-3 py-2 border border-meo-warm/20 rounded-xl focus:outline-none focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20 text-sm"
                    />
                  </div>
                </div>

                <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                  <div>
                    <label className="block text-sm font-medium text-meo-dark mb-1">
                      Email *
                    </label>
                    <input
                      type="email"
                      name="email"
                      value={customerData.email}
                      onChange={handleCustomerChange}
                      className="w-full px-3 py-2 border border-meo-warm/20 rounded-xl focus:outline-none focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20 text-sm"
                    />
                  </div>
                  <div>
                    <label className="block text-sm font-medium text-meo-dark mb-1">
                      Telefon *
                    </label>
                    <input
                      type="tel"
                      name="phone"
                      value={customerData.phone}
                      onChange={handleCustomerChange}
                      className="w-full px-3 py-2 border border-meo-warm/20 rounded-xl focus:outline-none focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20 text-sm"
                    />
                  </div>
                </div>

                <div>
                  <label className="block text-sm font-medium text-meo-dark mb-1">
                    Uwagi do zamówienia
                  </label>
                  <textarea
                    name="notes"
                    value={customerData.notes}
                    onChange={handleCustomerChange}
                    rows={3}
                    className="w-full px-3 py-2 border border-meo-warm/20 rounded-xl focus:outline-none focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20 text-sm"
                    placeholder="Dodatkowe informacje dla nas lub kuriera..."
                  />
                </div>
              </div>

              {/* Summary */}
              <h3 className="text-xl font-bold text-meo-dark mb-4">Podsumowanie zamówienia</h3>

              <div className="space-y-4 mb-6">
                <div className="flex justify-between text-meo-dark">
                  <span>Produkty ({getTotalItems()})</span>
                  <span>{subtotal.toFixed(2)} zł</span>
                </div>
                
                <div className="space-y-1">
                  <div className="flex justify-between text-rose-600 font-medium">
                    <span className="flex items-center gap-1">
                      <Heart className="w-4 h-4" />
                      Darowizna (5%)
                    </span>
                    <span>{donationAmount.toFixed(2)} zł</span>
                  </div>
                  <p className="text-xs text-meo-dark/70">
                    Z tego zamówienia część kwoty zostanie automatycznie przekazana na cele charytatywne.
                  </p>
                </div>
                
                <div className="flex justify-between text-meo-dark">
                  <span>Dostawa</span>
                  <span className="text-right">
                    {!hasSelectedShipping ? (
                      <span className="text-xs text-meo-dark/60">
                        Wybierz sposób dostawy, aby kontynuować
                      </span>
                    ) : requiresPickupPoint && !hasPickupPoint ? (
                      <span className="text-xs text-meo-dark/60">
                        Wybierz punkt dostawy, aby kontynuować
                      </span>
                    ) : (
                      <>
                        {shippingCost === 0 ? 'Gratis' : `${shippingCost.toFixed(2)} zł`}
                        {isFreeShipping && subtotal > 0 && (
                          <span className="ml-1 text-xs text-rose-600 block">
                            (darmowa dostawa od {freeShippingThreshold.toFixed(2)} zł)
                          </span>
                        )}
                      </>
                    )}
                  </span>
                </div>
                
                <div className="border-t border-meo-dark/10 pt-4">
                  <div className="flex justify-between text-xl font-bold text-meo-dark">
                    <span>Razem</span>
                    <span>{total.toFixed(2)} zł</span>
                  </div>
                </div>
              </div>

              {/* Promo Code */}
              <div className="mb-6">
                <div className="flex gap-2">
                  <input
                    type="text"
                    placeholder="Kod promocyjny"
                    value={promoCode}
                    onChange={(e) => setPromoCode(e.target.value)}
                    className="flex-1 px-4 py-3 border border-meo-warm/20 rounded-xl focus:outline-none focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20"
                  />
                  <button className="px-6 py-3 bg-meo-warm/10 text-meo-warm rounded-xl hover:bg-meo-warm/20 transition-colors">
                    Zastosuj
                  </button>
                </div>
              </div>

              {/* Payment Button */}
              {paymentError && (
                <div className="mb-3 text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl px-3 py-2">
                  {paymentError}
                </div>
              )}
              <button
                type="button"
                onClick={handlePay}
                disabled={!canSubmitOrder || isPaying}
                className={`w-full py-4 rounded-2xl font-semibold text-lg transition-all duration-300 flex items-center justify-center gap-2 group border-2 border-[#B4C588] ${
                  canSubmitOrder && !isPaying
                    ? 'bg-[#A3D9A5] text-black hover:bg-[#B4C588]'
                    : 'bg-[#A3D9A5] text-black opacity-60 cursor-not-allowed'
                }`}
              >
                <Icon icon="material-symbols:credit-card" className="w-5 h-5 rounded" />
                {isPaying ? 'Łączenie z Przelewy24…' : 'Przejdź do płatności'}
                <Icon icon="material-symbols:arrow-forward" className="w-5 h-5 group-hover:translate-x-1 transition-transform rounded" />
              </button>
            </div>

          </div>
        </div>
        <InpostPickupModal
          isOpen={isInpostModalOpen}
          onClose={() => setIsInpostModalOpen(false)}
          onSelected={(point) => {
            setSelectedInpostPoint(point)
            setIsInpostModalOpen(false)
          }}
        />
        <OrlenPickupModal
          isOpen={isOrlenModalOpen}
          onClose={() => setIsOrlenModalOpen(false)}
          onSelected={(point) => {
            setSelectedOrlenPoint(point)
            setIsOrlenModalOpen(false)
          }}
        />
      </div>
    </div>
  )
}