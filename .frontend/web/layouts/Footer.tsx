import React from 'react';

const Footer: React.FC = () => {
  return (
    <footer className="relative border-t border-white/10 bg-black">
      <div className="mx-auto max-w-7xl px-4 py-12 text-sm text-slate-300">
        <div className="grid gap-8 md:grid-cols-3">
          {/* Left: logo and mission */}

          <div>
            <div className="flex items-center gap-2">
              <img src="/img/company_logo_static.svg" alt="Logo firmy" className="h-6 w-6" />
              <span className="font-semibold text-white">RICE</span>
            </div>
            <p className="mt-3 max-w-sm text-slate-400">
              Łączymy technologię i człowieka w spójny ekosystem rozwiązań. Minimalizm, precyzja i odpowiedzialność za
              produkt.
            </p>
          </div>

          {/* Center: links */}
          <div className="flex flex-col items-start gap-2 md:items-center">
            <a href="#" className="link-underline hover:text-white">
              Regulamin
            </a>
            <a href="#" className="link-underline hover:text-white">
              Polityka prywatności
            </a>
          </div>

          {/* Right: socials + back-to-top */}
          <div className="flex w-full items-center gap-4 justify-end">
            <a aria-label="GitHub" href="#" className="smooth hover:text-white">
              GitHub
            </a>
            <a aria-label="LinkedIn" href="#" className="smooth hover:text-white">
              LinkedIn
            </a>
            <a aria-label="X" href="#" className="smooth hover:text-white">
              X
            </a>
            {/* Back-to-top inline button (to the right of X) */}
            <a
              href="#"
              aria-label="Powrót na górę"
              title="Powrót na górę"
              className="group relative ml-auto inline-flex items-center justify-center h-20 w-20 rounded-full bg-gradient-to-br from-amber-400 to-yellow-500 text-black shadow-md ring-1 ring-white/10 transition-all duration-200 hover:scale-105 hover:shadow-amber-500/20 focus:outline-none focus:ring-2 focus:ring-amber-300 active:scale-95 active:translate-y-0.5"
            >
              {/* Ostry efekt: bez rozmytej poświaty, tylko subtelny pierścień */}
              <span
                aria-hidden
                className="pointer-events-none absolute inset-0 rounded-full border border-amber-400/25 opacity-0 group-hover:opacity-100 transition-opacity"
              />
              <svg
                xmlns="http://www.w3.org/2000/svg"
                viewBox="0 0 24 24"
                fill="currentColor"
                className="h-8 w-8 transition-transform duration-200 group-hover:-translate-y-1 active:translate-y-0 rotate-180"
              >
                <path d="M12 4c.41 0 .75.34.75.75v11.19l3.72-3.72a.75.75 0 1 1 1.06 1.06l-5 5a.75.75 0 0 1-1.06 0l-5-5a.75.75 0 1 1 1.06-1.06l3.72 3.72V4.75c0-.41.34-.75.75-.75Z" />
              </svg>
            </a>
          </div>
        </div>
        <div className="mt-10 border-t border-white/10 pt-6 text-xs text-slate-400 text-center">
          © {new Date().getFullYear()} RICE. Wszystkie prawa zastrzeżone.
        </div>
      </div>
    </footer>
  );
};

export default Footer;
