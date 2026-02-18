import Link from 'next/link'
import { Icon } from '@iconify/react'

export default function Footer() {
  return (
    <footer className="bg-gradient-to-br from-gray-900 via-slate-900 to-black text-white relative overflow-hidden">
      <div className="max-w-7xl mx-auto px-6 lg:px-8 py-20">
        {/* Contact Info */}
        <div className="pt-8">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-8">
            <div className="flex items-center gap-3">
              <Icon icon="material-symbols:location-on" className="w-5 h-5 text-orange-400 rounded" />
              <div>
                <div className="text-white font-medium">Nasz adres</div>
                <div className="text-white/70">ul. Kocia 12, 00-123 Warszawa</div>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <Icon icon="material-symbols:mail" className="w-5 h-5 text-emerald-400 rounded" />
              <div>
                <div className="text-white font-medium">Email</div>
                <Link href="mailto:hello@meowtopia.pl" className="text-white/70 hover:text-emerald-400 transition-colors">
                  hello@meowtopia.pl
                </Link>
              </div>
            </div>

            <div className="flex items-center gap-3">
              <Icon icon="material-symbols:phone" className="w-5 h-5 text-emerald-400 rounded" />
              <div>
                <div className="text-white font-medium">Telefon</div>
                <Link href="tel:+48123456789" className="text-white/70 hover:text-emerald-400 transition-colors">
                  +48 123 456 789
                </Link>
              </div>
            </div>
          </div>

          {/* Social Media & Bottom */}
          <div className="flex flex-col md:flex-row justify-between items-center gap-6">
            <div className="flex items-center space-x-6">
              <Link
                href="https://facebook.com/meowtopia"
                className="p-3 bg-white/10 hover:bg-meo-rudy/20 rounded-lg transition-all duration-300 hover:scale-110"
                target="_blank"
                rel="noopener noreferrer"
              >
                <Icon icon="mdi:facebook" className="w-5 h-5 rounded" />
              </Link>
              <Link
                href="https://instagram.com/meowtopia"
                className="p-3 bg-white/10 hover:bg-orange-500/20 rounded-lg transition-all duration-300 hover:scale-110"
                target="_blank"
                rel="noopener noreferrer"
              >
                <Icon icon="mdi:instagram" className="w-5 h-5 rounded" />
              </Link>
              <Link
                href="https://youtube.com/meowtopia"
                className="p-3 bg-white/10 hover:bg-orange-500/20 rounded-lg transition-all duration-300 hover:scale-110"
                target="_blank"
                rel="noopener noreferrer"
              >
                <Icon icon="mdi:youtube" className="w-5 h-5 rounded" />
              </Link>
            </div>

            <div className="text-center text-white/60">
              <p className="mb-2">© 2025 MeoWTopia. Wszystkie prawa zastrzeżone.</p>
            </div>
          </div>
        </div>
      </div>
    </footer>
  )
}
