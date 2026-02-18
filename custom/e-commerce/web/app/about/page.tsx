import Link from 'next/link'
import { Icon } from '@iconify/react'

export default function AboutUsPage() {
  return (
    <div className="min-h-screen">
      <div className="max-w-7xl mx-auto px-6 lg:px-8 py-20">
        {/* Header */}
        <div className="text-center mb-16">
          <h1 className="text-4xl md:text-5xl font-display font-bold mb-4 text-meo-brown-800">
            O <span className="text-meo-accent">nas</span>
          </h1>
          <p className="text-xl text-meo-brown-700 max-w-3xl mx-auto">
            Poznaj naszą historię i misję pomagania zwierzętom
          </p>
        </div>

        {/* Main Content */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-12 mb-16">
          <div>
            <h2 className="text-2xl font-bold mb-4 text-meo-accent">Nasza Misja</h2>
            <p className="text-meo-brown-700 leading-relaxed mb-6">
              MeoWTopia to miejsce, gdzie każdy zakup ma znaczenie. 5% z każdego zamówienia automatycznie wspiera bezdomne zwierzęta.
            </p>
            <p className="text-meo-brown-700 leading-relaxed">
              Razem tworzymy lepszy świat dla kotów i innych zwierząt w potrzebie.
            </p>
          </div>

          <div>
            <h2 className="text-2xl font-bold mb-4 text-meo-nature">Nasza Historia</h2>
            <p className="text-meo-brown-700 leading-relaxed mb-6">
              Po zamknięciu kociej kawiarni postanowiliśmy kontynuować naszą misję w nowy sposób.
              Sprzedając kawę, herbatę i urocze plakaty z kotami, wspieramy fundacje ratujące zwierzęta.
            </p>
            <p className="text-meo-brown-700 leading-relaxed">
              Każdy kubek kawy to kawałek nadziei dla bezdomnych zwierząt.
            </p>
          </div>
        </div>

        {/* Contact Info - przeniesione z footera */}
        <div className="border-t border-meo-brown-300 pt-12">
          <h2 className="text-3xl font-bold mb-8 text-center text-meo-brown-800">
            <span className="text-meo-accent">Kontakt</span>
          </h2>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-12">
            <div className="flex items-center gap-3">
              <Icon icon="material-symbols:location-on" className="w-6 h-6 text-meo-accent rounded flex-shrink-0" />
              <div>
                <div className="text-meo-brown-800 font-medium text-lg mb-1">Nasz adres</div>
                <div className="text-meo-brown-600">ul. Kocia 12, 00-123 Warszawa</div>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <Icon icon="material-symbols:mail" className="w-6 h-6 text-meo-nature rounded flex-shrink-0" />
              <div>
                <div className="text-meo-brown-800 font-medium text-lg mb-1">Email</div>
                <Link href="mailto:hello@meowtopia.pl" className="text-meo-brown-600 hover:text-meo-nature transition-colors">
                  hello@meowtopia.pl
                </Link>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <Icon icon="material-symbols:phone" className="w-6 h-6 text-meo-nature rounded flex-shrink-0" />
              <div>
                <div className="text-meo-brown-800 font-medium text-lg mb-1">Telefon</div>
                <Link href="tel:+48123456789" className="text-meo-brown-600 hover:text-meo-nature transition-colors">
                  +48 123 456 789
                </Link>
              </div>
            </div>
          </div>

          {/* Social Media */}
          <div className="flex flex-col items-center gap-6">
            <h3 className="text-xl font-semibold text-meo-brown-800">Śledź nas</h3>
            <div className="flex items-center space-x-6">
              <Link
                href="https://facebook.com/meowtopia"
                className="p-3 bg-meo-beige-100 hover:bg-meo-beige-200 rounded-lg transition-all duration-300 hover:scale-110"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Facebook"
              >
                <Icon icon="mdi:facebook" className="w-6 h-6 rounded text-meo-brown-800" />
              </Link>
              <Link
                href="https://instagram.com/meowtopia"
                className="p-3 bg-meo-beige-100 hover:bg-orange-100 rounded-lg transition-all duration-300 hover:scale-110"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="Instagram"
              >
                <Icon icon="mdi:instagram" className="w-6 h-6 rounded text-meo-brown-800" />
              </Link>
              <Link
                href="https://youtube.com/meowtopia"
                className="p-3 bg-meo-beige-100 hover:bg-orange-100 rounded-lg transition-all duration-300 hover:scale-110"
                target="_blank"
                rel="noopener noreferrer"
                aria-label="YouTube"
              >
                <Icon icon="mdi:youtube" className="w-6 h-6 rounded text-meo-brown-800" />
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}

