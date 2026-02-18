'use client'

import Link from 'next/link'
import Image from 'next/image'
import { Icon } from '@iconify/react'
import { usePathname } from 'next/navigation'
import { useState, useEffect, useRef } from 'react'

export default function Header() {
  const pathname = usePathname()
  const [showUserMenu, setShowUserMenu] = useState(false)
  const menuRef = useRef<HTMLDivElement>(null)

  // Close menu when clicking outside
  useEffect(() => {
    const handleClickOutside = (event: MouseEvent) => {
      if (menuRef.current && !menuRef.current.contains(event.target as Node)) {
        setShowUserMenu(false)
      }
    }

    if (showUserMenu) {
      document.addEventListener('mousedown', handleClickOutside)
    }

    return () => {
      document.removeEventListener('mousedown', handleClickOutside)
    }
  }, [showUserMenu])

  const isActive = (path: string) => {
    if (path === '/') {
      return pathname === '/'
    }
    return pathname.startsWith(path)
  }

  const navButtonClass = (path: string) => {
    const baseClass = "flex items-center gap-2 px-4 py-2 text-sm font-semibold text-black border-2 border-[#B4C588] rounded-full transition-all duration-300 whitespace-nowrap shadow-sm"
    const activeClass = isActive(path)
      ? "bg-[#B4C588] text-black"
      : "hover:bg-[#B4C588] hover:text-black active:bg-[#B4C588] active:text-black"
    return `${baseClass} ${activeClass}`
  }

  return (
    <div className="sticky top-0 z-[2]">

      <header className="shadow-sm">
        {/* Górny pasek z hasłem, logo i przyciskami logowania */}
          <div className="relative bg-[#A3D9A5] text-meo-brown-800">
          <div className="max-w-7xl mx-auto px-6 py-2 flex items-center justify-between min-h-[80px] gap-4">
            {/* 1. LOGO - po lewej */}
            <div className="flex-shrink-0">
              <Link href="/" className="block focus:outline-none focus:ring-0 hover:outline-none active:outline-none" style={{ outline: 'none' }} aria-label="MeoWTopia - strona główna">
                <Image
                  src="/logomeow.svg"
                  alt="MeoWTopia Logo"
                  width={64}
                  height={64}
                  priority
                  className="drop-shadow-md w-16 h-auto"
                />
              </Link>
            </div>

            {/* 2. BLOCK ILE ZEBRALIŚMY */}
            <div className="hidden lg:flex items-center gap-2 bg-orange-500/10 backdrop-blur-sm rounded-xl px-3 py-2 border border-orange-500/20 flex-shrink-0">
              <Icon icon="material-symbols:card-giftcard" className="w-4 h-4 text-orange-600 rounded" />
              <div className="flex flex-col">
                <div className="text-xs text-black/70 leading-tight">Już przekazaliśmy</div>
                <div className="text-sm font-bold text-orange-600 leading-tight">2,847 zł</div>
                <div className="text-[10px] text-black/60 leading-tight">5% z każdego zamówienia</div>
              </div>
            </div>

            {/* 3. NAWIGACJA I PRZYCISKI LOGOWANIA - na końcu po prawej */}
            <div className="flex items-center gap-3 flex-shrink-0 ml-auto">
              {/* Nawigacja i przyciski - wszystkie w jednym stylu */}
              <nav className="hidden lg:flex items-center gap-3">
                <Link
                  href="/"
                  className={navButtonClass('/')}
                >
                  <Icon icon="material-symbols:store-rounded" className="w-4 h-4 rounded" />
                  <span>Sklep</span>
                </Link>
                <Link
                  href="/products"
                  className={navButtonClass('/products')}
                >
                  <Icon icon="material-symbols:inventory-2-rounded" className="w-4 h-4 rounded" />
                  <span>Produkty</span>
                </Link>
                <Link
                  href="/about"
                  className={navButtonClass('/about')}
                >
                  <Icon icon="material-symbols:info-i-rounded" className="w-4 h-4 rounded" />
                  <span>O nas</span>
                </Link>
              </nav>

              {/* Przyciski logowania i rejestracji (tryb bez aktywnego NextAuth) */}
              <Link
                href="/signin"
                className={navButtonClass('/signin')}
              >
                <Icon icon="material-symbols:login-rounded" className="w-4 h-4 rounded" />
                <span>Zaloguj</span>
              </Link>
              <Link
                href="/signup"
                className={navButtonClass('/signup')}
              >
                <Icon icon="material-symbols:person-add-rounded" className="w-4 h-4 rounded" />
                <span>Zarejestruj</span>
              </Link>
            </div>
          </div>
        </div>
      </header>
    </div>
  )
}
