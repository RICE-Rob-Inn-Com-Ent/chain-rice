import React from 'react'

const Footer: React.FC = () => {
  return (
    <footer className="border-t border-white/10 bg-black">
      <div className="mx-auto max-w-7xl px-4 py-12 text-sm text-slate-300">
        <div className="grid gap-8 md:grid-cols-3">
          {/* Left: logo and mission */}

          <div>
            <div className="flex items-center gap-2">
              <img
                src="/img/company_logo_static.svg"
                alt="Logo firmy"
                className="h-6 w-6"
              />
              <span className="gradient-text font-semibold">RICE</span>
            </div>
            <p className="mt-3 max-w-sm text-slate-400">Łączymy technologię i człowieka w spójny ekosystem rozwiązań. Minimalizm, precyzja i odpowiedzialność za produkt.</p>
          </div>

          {/* Center: links */}
          <div className="flex flex-col items-start gap-2 md:items-center">
            <a href="#top" className="link-underline hover:text-white">Powrót na górę</a>
            <a href="#" className="link-underline hover:text-white">Regulamin</a>
            <a href="#" className="link-underline hover:text-white">Polityka prywatności</a>
          </div>

          {/* Right: socials */}
          <div className="flex items-center gap-4 md:justify-end">
            <a aria-label="GitHub" href="#" className="smooth hover:text-white">GitHub</a>
            <a aria-label="LinkedIn" href="#" className="smooth hover:text-white">LinkedIn</a>
            <a aria-label="X" href="#" className="smooth hover:text-white">X</a>
          </div>
        </div>
        <div className="mt-10 border-t border-white/10 pt-6 text-xs text-slate-400">
          © {new Date().getFullYear()} RICE. Wszystkie prawa zastrzeżone.
        </div>
      </div>
    </footer>
  )
}

export default Footer
