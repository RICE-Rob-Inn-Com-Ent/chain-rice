'use client'

import { useCallback, useState } from 'react'
import { getInpostGeowidgetConfig } from './config'

declare global {
  interface Window {
    easyPackAsyncInit?: () => void
    easyPack?: any
  }
}

type PickupPointCallback = (point: any) => void

export function useInpostGeowidget() {
  const [isLoading, setIsLoading] = useState(false)
  const [isLoaded, setIsLoaded] = useState(false)

  const loadScript = useCallback(async () => {
    if (isLoaded || typeof document === 'undefined') return
    if (isLoading) return

    const { scriptUrl, primaryColor } = getInpostGeowidgetConfig()

    setIsLoading(true)

    await new Promise<void>((resolve, reject) => {
      const existing = document.querySelector<HTMLScriptElement>(
        'script[data-inpost-geowidget="true"]'
      )
      if (existing) {
        resolve()
        return
      }

      const script = document.createElement('script')
      script.src = scriptUrl
      script.async = true
      script.dataset.inpostGeowidget = 'true'

      window.easyPackAsyncInit = function () {
        try {
          if (window.easyPack) {
            // Minimalna, bezpieczna konfiguracja – szczegóły (kolory itp.)
            // zależą od wersji SDK, więc przekazujemy tylko akcent.
            try {
              window.easyPack.init({
                // Wymuszenie paczkomatów
                mapType: 'parcelLockers',
                searchType: 'parcelLockers',
                // @ts-ignore – zależy od wersji SDK
                styleConfig: {
                  primaryColor,
                },
              })
            } catch (e) {
              console.error('easyPack.init error', e)
            }
          }
        } catch (e) {
          console.error('InPost Geowidget init error', e)
        }
        resolve()
      }

      script.onload = () => {
        // easyPackAsyncInit zostanie wywołany przez sam skrypt
      }
      script.onerror = (err) => {
        console.error('Failed to load InPost Geowidget script', err)
        reject(err)
      }

      document.body.appendChild(script)
    })

    setIsLoaded(true)
    setIsLoading(false)
  }, [isLoaded, isLoading])

  const openGeowidget = useCallback(
    async (onSelected: PickupPointCallback) => {
      try {
        await loadScript()

        if (!window.easyPack || typeof window.easyPack.modalMap !== 'function') {
          console.error('InPost Geowidget is not available on window.easyPack')
          return
        }

        window.easyPack.modalMap(
          (point: any) => {
            if (point) {
              onSelected(point)
            }
          },
          {
            width: 600,
            height: 600,
          }
        )
      } catch (e) {
        console.error('Error opening InPost Geowidget', e)
      }
    },
    [loadScript]
  )

  return {
    openGeowidget,
    isLoading,
    isLoaded,
  }
}


