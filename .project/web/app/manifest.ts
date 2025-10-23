import type { MetadataRoute } from 'next'

export default function manifest(): MetadataRoute.Manifest {
  return {
    name: 'RICE — Nowoczesna firma technologiczna',
    short_name: 'RICE',
    description: 'Minimalistyczna, czarno-biała wizytówka IT z SEO/SSR i szybkim UX.',
    start_url: '/',
    display: 'standalone',
    background_color: '#000000',
    theme_color: '#0b0f1a',
    icons: [
      {
        src: '/icon-192.png',
        sizes: '192x192',
        type: 'image/png'
      },
      {
        src: '/icon-512.png',
        sizes: '512x512',
        type: 'image/png'
      },
      {
        src: '/apple-touch-icon.png',
        sizes: '180x180',
        type: 'image/png',
        purpose: 'maskable any'
      }
    ]
  }
}
