'use client'

import Link from 'next/link'
import { Icon } from '@iconify/react'

export default function NotFound() {
  return (
    <div className="min-h-screen bg-meo-bg flex items-center justify-center px-4">
      <div className="max-w-md mx-auto text-center">
        <div className="mb-8">
          <h1 className="text-6xl font-bold text-meo-brown-800 mb-4">404</h1>
          <h2 className="text-2xl font-display font-bold text-meo-brown-800 mb-4">
            Produktu nie znaleziono
          </h2>
          <p className="text-meo-brown-600 mb-8">
            Produkt, którego szukasz nie istnieje lub został przeniesiony.
          </p>
        </div>

        <div className="space-y-4">
          <Link
            href="/"
            className="inline-flex items-center space-x-2 bg-meo-accent text-white px-6 py-3 rounded-xl hover:bg-meo-accent/90 transition-colors font-medium"
          >
            <Icon icon="material-symbols:home" className="w-5 h-5 rounded" />
            <span>Strona główna</span>
          </Link>

          <div>
            <button
              onClick={() => window.history.back()}
              className="inline-flex items-center space-x-2 text-meo-brown-600 hover:text-meo-accent transition-colors"
            >
              <Icon icon="material-symbols:arrow-back" className="w-4 h-4 rounded" />
              <span>Powrót</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  )
}
