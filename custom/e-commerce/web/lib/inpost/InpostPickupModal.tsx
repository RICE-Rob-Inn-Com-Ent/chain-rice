'use client'

import { useEffect } from 'react'

declare global {
  namespace JSX {
    // Pozwala użyć web komponentu <inpost-geowidget /> w TSX
    interface IntrinsicElements {
      'inpost-geowidget': any
    }
  }
}

export interface InpostPointSummary {
  name: string
  address: string
}

interface InpostPickupModalProps {
  isOpen: boolean
  onClose: () => void
  onSelected: (point: InpostPointSummary) => void
}

// Używamy takich nazw, jak masz w swoim .env:
// INPOST_GEOWIDGET_TOKEN=...
// (NEXT_PUBLIC_INPOST_GEOWIDGET_TOKEN jest opcjonalne)
const GEOWIDGET_TOKEN =
  process.env.INPOST_GEOWIDGET_TOKEN ||
  process.env.NEXT_PUBLIC_INPOST_GEOWIDGET_TOKEN ||
  ''

export function InpostPickupModal({ isOpen, onClose, onSelected }: InpostPickupModalProps) {
  // Doładuj CSS i JS Geowidgeta tylko raz
  useEffect(() => {
    if (typeof document === 'undefined') return

    const existingScript = document.querySelector<HTMLScriptElement>(
      'script[data-inpost-geowidget-new="true"]'
    )
    const existingLink = document.querySelector<HTMLLinkElement>(
      'link[data-inpost-geowidget-new="true"]'
    )

    if (!existingLink) {
      const link = document.createElement('link')
      link.rel = 'stylesheet'
      link.href = 'https://geowidget.inpost.pl/inpost-geowidget.css'
      link.dataset.inpostGeowidgetNew = 'true'
      document.head.appendChild(link)
    }

    if (!existingScript) {
      const script = document.createElement('script')
      script.src = 'https://geowidget.inpost.pl/inpost-geowidget.js'
      script.defer = true
      script.dataset.inpostGeowidgetNew = 'true'
      document.body.appendChild(script)
    }
  }, [])

  // Nasłuchuj na wybór punktu
  useEffect(() => {
    if (!isOpen || typeof document === 'undefined') return

    const handler = (event: Event) => {
      const detail: any = (event as CustomEvent).detail
      if (!detail) return

      const name = detail.name || detail.display_name || 'Paczkomat InPost'
      const address =
        detail.address?.formatted ||
        [detail.address?.street, detail.address?.building_number, detail.address?.city]
          .filter(Boolean)
          .join(' ') ||
        ''

      onSelected({ name, address })
      onClose()
    }

    document.addEventListener('onpointselect', handler as EventListener)

    return () => {
      document.removeEventListener('onpointselect', handler as EventListener)
    }
  }, [isOpen, onClose, onSelected])

  if (!isOpen) return null

  return (
    <div className="fixed inset-0 z-[9999] flex items-center justify-center bg-black/40">
      <div className="bg-white rounded-2xl shadow-2xl max-w-3xl w-full mx-4 p-4 flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <h2 className="text-lg font-semibold text-meo-dark">Wybierz paczkomat InPost</h2>
          <button
            type="button"
            className="text-sm text-gray-500 hover:text-gray-800"
            onClick={onClose}
          >
            Zamknij
          </button>
        </div>

        <div className="h-[480px] w-full border border-gray-200 rounded-xl overflow-hidden">
          {/* Oficjalny web komponent InPost */}
          <inpost-geowidget
            token={GEOWIDGET_TOKEN}
            language="pl"
            config="parcelCollect"
            style={{ width: '100%', height: '100%', display: 'block' }}
          />
        </div>
      </div>
    </div>
  )
}


