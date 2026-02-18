'use client'

import { useEffect, useState } from 'react'

interface StoreSettingsResponse {
  freeShippingThreshold: number
}

export default function OfertaPage({
  params,
}: {
  params: { username: string }
}) {
  const [freeShippingThreshold, setFreeShippingThreshold] = useState<number>(199)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState<string | null>(null)

  useEffect(() => {
    const fetchSettings = async () => {
      try {
        const res = await fetch('/api/store-settings')
        if (res.ok) {
          const data = (await res.json()) as StoreSettingsResponse
          if (typeof data.freeShippingThreshold === 'number') {
            setFreeShippingThreshold(data.freeShippingThreshold)
          }
        }
      } catch (e) {
        console.error('Error loading store settings', e)
        setError('Nie udało się załadować ustawień sklepu.')
      } finally {
        setLoading(false)
      }
    }

    fetchSettings()
  }, [])

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setSaving(true)
    setError(null)
    setSuccess(null)

    try {
      const res = await fetch('/api/store-settings', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ freeShippingThreshold }),
      })

      if (!res.ok) {
        const data = await res.json().catch(() => ({}))
        throw new Error(data.error || 'Błąd zapisu ustawień')
      }

      setSuccess('Ustawienia zostały zapisane.')
    } catch (e: any) {
      setError(e.message || 'Nie udało się zapisać ustawień.')
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-3xl font-bold text-gray-900">Oferta</h1>
        <p className="text-gray-600 mt-2">
          Ustawienia oferty sklepu, w tym próg darmowej dostawy.
        </p>
      </div>

      <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-200 max-w-xl">
        <h2 className="text-xl font-semibold text-gray-900 mb-4">
          Darmowa dostawa
        </h2>

        {loading ? (
          <p className="text-gray-500 text-sm">Ładowanie ustawień...</p>
        ) : (
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label
                htmlFor="freeShippingThreshold"
                className="block text-sm font-medium text-gray-700 mb-1"
              >
                Próg darmowej dostawy (zł)
              </label>
              <div className="mt-1 flex rounded-md shadow-sm">
                <input
                  id="freeShippingThreshold"
                  type="number"
                  step="1"
                  min="0"
                  value={Number.isNaN(freeShippingThreshold) ? '' : freeShippingThreshold}
                  onChange={(e) => setFreeShippingThreshold(Number(e.target.value))}
                  className="block w-full rounded-md border-gray-300 focus:border-blue-500 focus:ring-blue-500 sm:text-sm"
                />
              </div>
              <p className="mt-1 text-xs text-gray-500">
                Powyżej tej kwoty wartość dostawy w koszyku będzie wynosić 0 zł
                (z wyjątkiem odbioru osobistego, który i tak jest darmowy).
              </p>
            </div>

            {error && (
              <p className="text-sm text-red-600">
                {error}
              </p>
            )}
            {success && (
              <p className="text-sm text-green-600">
                {success}
              </p>
            )}

            <div className="pt-2">
              <button
                type="submit"
                disabled={saving}
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-blue-600 hover:bg-blue-700 disabled:opacity-60 disabled:cursor-not-allowed"
              >
                {saving ? 'Zapisywanie...' : 'Zapisz ustawienia'}
              </button>
            </div>
          </form>
        )}
      </div>
    </div>
  )
}






































