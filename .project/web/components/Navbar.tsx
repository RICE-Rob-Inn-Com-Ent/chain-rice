"use client";
import React from 'react'
import Link from 'next/link'
import { Button } from '@web/components/ui/Button'

const Navbar: React.FC = () => {
  return (
    <header className="sticky top-0 z-40 w-full border-b border-white/10 bg-black/60 backdrop-blur-md">
      <div className="mx-auto flex max-w-7xl items-center justify-between px-4 py-3">
        <Link href="/" className="flex items-center gap-2">
          <img
            src="../img/company_logo_animated.svg"
            alt="Logo firmy"
            className="h-20 w-20 transition"
          />
          <span className="text-sm font-semibold tracking-wide gradient-on-hover text-white">RICE</span>
        </Link>
        <nav className="hidden items-center gap-6 text-sm text-slate-200 md:flex">
          <Link href="/about" className="link-underline hover:text-white">O nas</Link>
          <Link href="/services" className="link-underline hover:text-white">Usługi</Link>
          <Link href="/portfolio" className="link-underline hover:text-white">Portfolio</Link>
          <Link href="/pricing" className="link-underline hover:text-white">Cennik</Link>
          <Link href="/contact" className="link-underline hover:text-white">Kontakt</Link>
        </nav>
        <div className="flex items-center gap-2">
          <Link href="/contact">
            <Button size="sm" variant="outline" className="smooth">Porozmawiajmy</Button>
          </Link>
        </div>
      </div>
    </header>
  )
}

export default Navbar
