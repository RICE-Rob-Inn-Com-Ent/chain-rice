'use client'

import { useState } from 'react'

export interface OrlenPointSummary {
  name: string
  address: string
}

interface OrlenPickupModalProps {
  isOpen: boolean
  onClose: () => void
  onSelected: (point: OrlenPointSummary) => void
}

export function OrlenPickupModal({ isOpen, onClose, onSelected }: OrlenPickupModalProps) {
  const [name, setName] = useState('')
  const [address, setAddress] = useState('')
  const [isSubmitting, setIsSubmitting] = useState(false)
  const [error, setError] = useState<string | null>(null)

  if (!isOpen) return null

  const handleSave = async () => {
    const trimmedName = name.trim()
    const trimmedAddress = address.trim()

    if (!trimmedName || !trimmedAddress || isSubmitting) return

    setIsSubmitting(true)
    setError(null)

    try {
      // Wyślij dane punktu do backendu, który może je dalej przekazać do API ORLEN Paczki.
      const res = await fetch('/api/orlen/pickup-point', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          name: trimmedName,
          address: trimmedAddress
        })
      })

      if (!res.ok) {
        const payload = await res.json().catch(() => null)
        console.error('ORLEN Paczka proxy error', payload ?? res.statusText)
        setError('Nie udało się zapisać punktu w ORLEN Paczce. Spróbuj ponownie lub wybierz inny punkt.')
      } else {
        onSelected({ name: trimmedName, address: trimmedAddress })
        onClose()
      }
    } catch (err) {
      console.error('ORLEN Paczka request failed', err)
      setError('Wystąpił błąd połączenia z ORLEN Paczką. Spróbuj ponownie później.')
    } finally {
      setIsSubmitting(false)
    }
  }

  return (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/40">
      <div className="bg-white rounded-2xl shadow-2xl max-w-lg w-full mx-4 p-6 flex flex-col gap-4">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-meo-dark">Wybierz punkt Orlen Paczka</h2>
          <button
            type="button"
            className="text-sm text-gray-500 hover:text-gray-800"
            onClick={onClose}
          >
            Zamknij
          </button>
        </div>

        <p className="text-sm text-meo-dark/70">
          Podaj nazwę oraz adres punktu Orlen Paczka, do którego mamy wysłać Twoją paczkę.
        </p>

        {error && (
          <div className="text-xs text-red-600 bg-red-50 border border-red-100 rounded-xl px-3 py-2">
            {error}
          </div>
        )}

        <div className="space-y-3">
          <div>
            <label className="block text-sm font-medium text-meo-dark mb-1">
              Nazwa punktu
            </label>
            <input
              type="text"
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Np. Punkt Orlen Paczka 1234"
              className="w-full px-4 py-3 border border-meo-warm/20 rounded-xl focus:outline-none focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20"
            />
          </div>

          <div>
            <label className="block text-sm font-medium text-meo-dark mb-1">
              Adres punktu
            </label>
            <input
              type="text"
              value={address}
              onChange={(e) => setAddress(e.target.value)}
              placeholder="Ulica, numer, miasto"
              className="w-full px-4 py-3 border border-meo-warm/20 rounded-xl focus:outline-none focus:border-meo-warm focus:ring-2 focus:ring-meo-warm/20"
            />
          </div>
        </div>

        <button
          type="button"
          onClick={handleSave}
          disabled={!name.trim() || !address.trim() || isSubmitting}
          className="w-full bg-meo-warm text-white py-3 rounded-2xl font-semibold text-sm shadow-meo-warm hover:bg-cream-700 transition-all disabled:opacity-60 disabled:cursor-not-allowed"
        >
          {isSubmitting ? 'Łączenie z ORLEN Paczka…' : 'Zapisz punkt Orlen Paczka'}
        </button>
      </div>
    </div>
  )
}


