import Image from 'next/image'
import Link from 'next/link'
import { Icon } from '@iconify/react'

interface Foundation {
  id: string
  name: string
  description: string
  website?: string
  logo?: string
  totalReceived: number
  location?: string
  featured?: boolean
}

interface FoundationShowcaseProps {
  foundations: Foundation[]
  title?: string
  showAll?: boolean
}

export default function FoundationShowcase({
  foundations,
  title = "Wspieramy razem",
  showAll = true
}: FoundationShowcaseProps) {
  const displayedFoundations = showAll ? foundations : foundations.slice(0, 3)

  return (
    <section className="section-spacing bg-warm-gradient">
      <div className="max-w-7xl mx-auto container-padding">

        {/* Header */}
        <div className="text-center mb-16">
          <div className="flex items-center justify-center space-x-3 mb-6">
            <Icon icon="material-symbols:favorite" className="w-8 h-8 text-danger animate-soft-pulse rounded" style={{ fill: 'currentColor' }} />
            <h2 className="section-header">{title}</h2>
            <Icon icon="material-symbols:favorite" className="w-8 h-8 text-danger animate-soft-pulse rounded" style={{ fill: 'currentColor' }} />
          </div>
          <p className="section-subtitle">
            Każdy Twój zakup pomaga tym niesamowitym organizacjom ratować zwierzęta.
            Zobacz, komu pomagasz i jak Twoje pieniądze zmieniają świat.
          </p>
        </div>

        {/* Foundations grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8 mb-12">
          {displayedFoundations.map((foundation, index) => (
            <div
              key={foundation.id}
              className="card-warm group hover:scale-105 transition-all duration-300"
              style={{ animationDelay: `${index * 0.1}s` }}
            >
              {/* Foundation logo/header */}
              <div className="flex items-start space-x-4 mb-4">
                {foundation.logo ? (
                  <div className="relative w-16 h-16 rounded-2xl overflow-hidden bg-warm-200">
                    <Image
                      src={foundation.logo}
                      alt={`Logo ${foundation.name}`}
                      fill
                      className="object-cover"
                    />
                  </div>
                ) : (
                  <div className="w-16 h-16 bg-gradient-to-br from-accent to-pastel-lavender-400 rounded-2xl flex items-center justify-center">
                    <Icon icon="material-symbols:favorite" className="w-8 h-8 text-white rounded" style={{ fill: 'currentColor' }} />
                  </div>
                )}

                <div className="flex-1 min-w-0">
                  <h3 className="font-heading font-bold text-graphite-800 text-lg mb-1 group-hover:text-primary transition-colors">
                    {foundation.name}
                  </h3>
                  {foundation.location && (
                    <div className="flex items-center space-x-1 text-warm-600 text-sm mb-2">
                      <Icon icon="material-symbols:location-on" className="w-3 h-3 rounded" />
                      <span>{foundation.location}</span>
                    </div>
                  )}
                  {foundation.featured && (
                    <span className="inline-block bg-accent text-white text-xs px-2 py-1 rounded-full">
                      ⭐ Polecana
                    </span>
                  )}
                </div>
              </div>

              {/* Description */}
              <p className="text-graphite-700 text-sm leading-relaxed mb-6 line-clamp-3">
                {foundation.description}
              </p>

              {/* Stats */}
              <div className="bg-white/60 rounded-2xl p-4 mb-6">
                <div className="text-center">
                  <div className="text-2xl font-bold text-primary mb-1">
                    {foundation.totalReceived.toLocaleString('pl-PL', {
                      minimumFractionDigits: 2,
                      maximumFractionDigits: 2
                    })} zł
                  </div>
                  <div className="text-xs text-warm-600">już przekazane od nas</div>
                </div>
              </div>

              {/* Actions */}
              <div className="flex space-x-2">
                <Link
                  href={`/fundacja/${foundation.id}`}
                  className="flex-1 text-center py-2 px-4 bg-warm-300 text-graphite-800 rounded-xl font-medium hover:bg-warm-400 transition-colors"
                >
                  Zobacz więcej
                </Link>
                {foundation.website && (
                  <a
                    href={foundation.website}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="py-2 px-4 bg-primary text-cream rounded-xl font-medium hover:bg-graphite-700 transition-colors inline-flex items-center space-x-1"
                  >
                    <Icon icon="material-symbols:open-in-new" className="w-4 h-4 rounded" />
                    <span className="sr-only">Odwiedź stronę</span>
                  </a>
                )}
              </div>
            </div>
          ))}
        </div>

        {/* Call to action */}
        <div className="text-center">
          <div className="bg-white/80 rounded-3xl p-8 max-w-2xl mx-auto shadow-soft">
            <h3 className="text-2xl font-heading font-bold text-graphite-800 mb-4">
              Chcesz pomóc jeszcze bardziej? 🐾
            </h3>
            <p className="text-graphite-600 mb-6 leading-relaxed">
              Oprócz automatycznych 5% z każdego zamówienia, możesz również przekazać dodatkową darowiznę
              bezpośrednio wybranej fundacji lub zostać wolontariuszem.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link href="/fundacje" className="btn-primary">
                <Icon icon="material-symbols:favorite" className="w-4 h-4 mr-2 rounded" />
                Zobacz wszystkie fundacje
              </Link>
              <Link href="/wolontariat" className="btn-secondary">
                Zostań wolontariuszem
              </Link>
            </div>
          </div>
        </div>
      </div>
    </section>
  )
}
