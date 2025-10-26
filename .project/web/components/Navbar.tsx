"use client";
import React from 'react'
import Link from 'next/link'
import { Button } from '@web/components/ui/Button'
import ThemeToggle from './ThemeToggle'

const Navbar: React.FC = () => {
  return (
  <header className="fixed top-0 left-0 right-0 z-50 w-full border-b border-white/10 bg-[#0b0f1a] dark:bg-black shadow-[0_8px_24px_rgba(0,0,0,0.35)] ring-1 ring-white/10">
      <div className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3">
        <Link href="/" className="flex items-center gap-2">
          <img
            src="../img/company_logo_animated.svg"
            alt="Logo firmy"
            className="h-20 w-20 transition"
          />
          <span className="text-base md:text-lg font-semibold tracking-[0.09em] gradient-on-hover text-white">RICE</span>
        </Link>
        <nav className="hidden md:flex">
          <div className="nav-capsule rounded-full px-1 py-1 flex items-center gap-1">
            <Link href="/about" className="nav-item">O nas</Link>
            <Link href="/services" className="nav-item">Usługi</Link>
            <Link href="/portfolio" className="nav-item">Portfolio</Link>
            <Link href="/pricing" className="nav-item">Cennik</Link>
            <Link href="/contact" className="nav-item">Kontakt</Link>
          </div>
        </nav>
        <div className="flex items-center gap-2">
          <ThemeToggle />
          <Link href="/contact" className="cta-neutral" aria-label="Napisz do nas">
            <span className="cta-neutral__inner">Napisz do nas</span>
          </Link>
        </div>
      </div>
    </header>
  )
}

export default Navbar
