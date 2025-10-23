import './globals.css'
import type { Metadata, Viewport } from 'next'
import React from 'react'
import Navbar from '../components/Navbar'
import Footer from '../components/Footer'
import { Poppins, Orbitron, Inter } from 'next/font/google'
import dynamic from 'next/dynamic'

const ChatWidget = dynamic(() => import('../components/ChatWidget'), { ssr: false })

const poppins = Poppins({ subsets: ['latin'], weight: ['400','600','700'], variable: '--font-poppins' })
const orbitron = Orbitron({ subsets: ['latin'], weight: ['500','700'], variable: '--font-orbitron' })
const inter = Inter({ subsets: ['latin'], variable: '--font-inter' })

const siteUrl = process.env.NEXT_PUBLIC_SITE_URL || 'http://localhost:3000'

export const metadata: Metadata = {
  metadataBase: new URL(siteUrl),
  title: {
    default: 'RICE — Nowoczesna firma technologiczna',
    template: '%s | RICE'
  },
  description: 'Wizytówka nowoczesnej firmy z naciskiem na innowacje, AI i skalowalne rozwiązania.',
  keywords: ['RICE', 'AI', 'software', 'technologia', 'innowacje', 'chmura', 'skalowalność'],
  applicationName: 'RICE',
  authors: [{ name: 'RICE Team' }],
  alternates: {
    canonical: '/',
  },
  openGraph: {
    title: 'RICE — Nowoczesna firma technologiczna',
    description: 'Innowacyjne rozwiązania oparte na AI i nowoczesnej architekturze.',
    url: siteUrl,
    siteName: 'RICE',
    locale: 'pl_PL',
    type: 'website'
  },
  twitter: {
    card: 'summary_large_image',
    title: 'RICE — Nowoczesna firma technologiczna',
    description: 'Innowacyjne rozwiązania oparte na AI i nowoczesnej architekturze.',
    creator: '@rice',
  },
  robots: {
    index: true,
    follow: true,
  },
  category: 'technology',
  icons: {
    icon: [
      { url: '/icon.svg', type: 'image/svg+xml' },
      { url: '/icon-192.png', sizes: '192x192', type: 'image/png' },
      { url: '/icon-512.png', sizes: '512x512', type: 'image/png' },
    ],
    apple: [{ url: '/apple-touch-icon.png', sizes: '180x180', type: 'image/png' }],
    other: [{ rel: 'mask-icon', url: '/icon.svg', color: '#ffffff' }]
  },
  manifest: '/manifest.webmanifest',
}

export const viewport: Viewport = {
  themeColor: '#0b0f1a',
  width: 'device-width',
  initialScale: 1,
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="pl" className={`${poppins.variable} ${orbitron.variable} ${inter.variable}`}>
      <body className="min-h-dvh bg-black text-slate-100 antialiased font-sans">
        <Navbar />
        <main className="relative">{children}</main>
        <Footer />
        <ChatWidget />
      </body>
    </html>
  )
}
