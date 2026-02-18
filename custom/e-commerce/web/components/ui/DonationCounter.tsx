'use client'

import { useState, useEffect } from 'react'
import { Icon } from '@iconify/react'

interface DonationCounterProps {
  totalDonated?: number
  ordersCount?: number
  targetAmount?: number
}

export default function DonationCounter({
  totalDonated = 12847.50,
  ordersCount = 1247,
  targetAmount = 15000
}: DonationCounterProps) {
  const [animatedTotal, setAnimatedTotal] = useState(0)
  const [animatedOrders, setAnimatedOrders] = useState(0)

  const progressPercentage = Math.min((totalDonated / targetAmount) * 100, 100)

  useEffect(() => {
    // Animate the counters
    const duration = 2000 // 2 seconds
    const steps = 60
    const totalIncrement = totalDonated / steps
    const ordersIncrement = ordersCount / steps

    let currentStep = 0
    const timer = setInterval(() => {
      currentStep++
      setAnimatedTotal(Math.min(currentStep * totalIncrement, totalDonated))
      setAnimatedOrders(Math.min(Math.floor(currentStep * ordersIncrement), ordersCount))

      if (currentStep >= steps) {
        clearInterval(timer)
      }
    }, duration / steps)

    return () => clearInterval(timer)
  }, [totalDonated, ordersCount])

  return (
    <div className="bg-donation-gradient rounded-3xl p-8 text-center text-white shadow-warm">
      <div className="mb-6">
        <div className="flex items-center justify-center space-x-2 mb-4">
          <Icon icon="material-symbols:favorite" className="w-8 h-8 animate-soft-pulse rounded" style={{ fill: 'currentColor' }} />
          <h3 className="text-2xl font-heading font-bold">Razem pomagamy!</h3>
          <Icon icon="material-symbols:favorite" className="w-8 h-8 animate-soft-pulse rounded" style={{ fill: 'currentColor' }} />
        </div>
        <p className="text-white/90 text-lg leading-relaxed">
          Dzięki Waszym zakupom już przekazaliśmy na ratowanie zwierząt
        </p>
      </div>

      {/* Main counter */}
      <div className="mb-8">
        <div className="text-5xl md:text-6xl font-bold mb-2">
          {animatedTotal.toLocaleString('pl-PL', {
            minimumFractionDigits: 2,
            maximumFractionDigits: 2
          })} zł
        </div>
        <div className="flex items-center justify-center space-x-4 text-white/80">
          <span>z {animatedOrders.toLocaleString('pl-PL')} zamówień</span>
          <div className="flex items-center space-x-1">
            <Icon icon="material-symbols:trending-up" className="w-4 h-4 rounded" />
            <span className="text-sm">+5% z każdego</span>
          </div>
        </div>
      </div>

      {/* Progress bar */}
      <div className="mb-6">
        <div className="flex justify-between items-center mb-2 text-sm text-white/80">
          <span>Postęp do celu</span>
          <span>{targetAmount.toLocaleString('pl-PL')} zł</span>
        </div>
        <div className="w-full bg-white/20 rounded-full h-3 overflow-hidden">
          <div
            className="h-full bg-white rounded-full transition-all duration-1000 ease-out"
            style={{ width: `${progressPercentage}%` }}
          ></div>
        </div>
        <div className="text-right text-sm text-white/80 mt-1">
          {progressPercentage.toFixed(1)}% osiągnięte
        </div>
      </div>

      {/* Call to action */}
      <div className="bg-white/10 rounded-2xl p-4 backdrop-blur-sm">
        <p className="text-sm text-white/90 mb-2">
          <span className="font-semibold">Mały gest, wielkie serce</span>
        </p>
        <p className="text-xs text-white/70">
          Każdy kubek kawy to kawałek nadziei dla bezdomnych zwierząt ❤️
        </p>
      </div>
    </div>
  )
}
