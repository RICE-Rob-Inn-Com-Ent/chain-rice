import React from "react";
import { Link, useLocation } from "react-router-dom";
import { Icon } from "@iconify/react";

const navLinks = [
  { to: "/", label: "Home" },
  { to: "/pricing", label: "Pricing" },
  { to: "/about", label: "About" },
  { to: "/demo", label: "Demo" },
  { to: "/contact", label: "Contact" },
];

export const Layout: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const location = useLocation();

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-950 via-purple-950 to-slate-950">
      {/* Header/Navigation */}
      <header className="bg-black/30 backdrop-blur-lg border-b border-white/10 sticky top-0 z-50">
        <nav className="max-w-7xl mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            {/* Logo */}
            <Link to="/" className="flex items-center gap-3 hover:opacity-80 transition">
              <span className="text-4xl">🧬</span>
              <div>
                <h1 className="text-2xl font-bold text-transparent bg-clip-text bg-gradient-to-r from-purple-400 to-pink-400">
                  Rice AI
                </h1>
                <p className="text-xs text-gray-400">Powered by GiPT-1</p>
              </div>
            </Link>

            {/* Nav Links */}
            <div className="hidden md:flex items-center gap-1">
              {navLinks.map((link) => (
                <Link
                  key={link.to}
                  to={link.to}
                  className={`px-4 py-2 rounded-lg font-medium transition ${
                    location.pathname === link.to
                      ? "bg-white/20 text-white"
                      : "text-gray-300 hover:bg-white/10 hover:text-white"
                  }`}
                >
                  {link.label}
                </Link>
              ))}
            </div>

            {/* CTA Button */}
            <div className="flex items-center gap-3">
              <a
                href="http://localhost:3001"
                target="_blank"
                rel="noopener noreferrer"
                className="px-4 py-2 bg-white/10 hover:bg-white/20 text-white rounded-lg font-semibold transition text-sm"
              >
                Admin Panel →
              </a>
              <Link
                to="/demo"
                className="px-6 py-2 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700 text-white rounded-lg font-semibold transition"
              >
                Try Demo
              </Link>
            </div>
          </div>
        </nav>
      </header>

      {/* Main Content */}
      <main>{children}</main>

      {/* Footer */}
      <footer className="bg-black/30 backdrop-blur-lg border-t border-white/10 mt-20">
        <div className="max-w-7xl mx-auto px-6 py-12">
          <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
            {/* Brand */}
            <div className="col-span-1">
              <div className="flex items-center gap-2 mb-4">
                <span className="text-3xl">🧬</span>
                <h3 className="text-xl font-bold text-white">Rice AI</h3>
              </div>
              <p className="text-gray-400 text-sm">
                Revolutionary multimodal AI platform combining 6 specialized models into one.
              </p>
            </div>

            {/* Product */}
            <div>
              <h4 className="text-white font-semibold mb-3">Product</h4>
              <ul className="space-y-2 text-sm">
                <li>
                  <Link to="/demo" className="text-gray-400 hover:text-white transition">
                    Try Demo
                  </Link>
                </li>
                <li>
                  <Link to="/pricing" className="text-gray-400 hover:text-white transition">
                    Pricing
                  </Link>
                </li>
                <li>
                  <Link to="/about" className="text-gray-400 hover:text-white transition">
                    About GiPT-1
                  </Link>
                </li>
              </ul>
            </div>

            {/* Resources */}
            <div>
              <h4 className="text-white font-semibold mb-3">Resources</h4>
              <ul className="space-y-2 text-sm">
                <li>
                  <a href="https://github.com/rice-mono" className="text-gray-400 hover:text-white transition">
                    Documentation
                  </a>
                </li>
                <li>
                  <a href="https://github.com/rice-mono" className="text-gray-400 hover:text-white transition">
                    GitHub
                  </a>
                </li>
                <li>
                  <a href="https://npmjs.com/package/@rice-mono/ui-kit" className="text-gray-400 hover:text-white transition">
                    NPM Package
                  </a>
                </li>
              </ul>
            </div>

            {/* Contact */}
            <div>
              <h4 className="text-white font-semibold mb-3">Contact</h4>
              <ul className="space-y-2 text-sm">
                <li>
                  <Link to="/contact" className="text-gray-400 hover:text-white transition">
                    Get in Touch
                  </Link>
                </li>
                <li>
                  <a href="mailto:hello@rice-ai.com" className="text-gray-400 hover:text-white transition">
                    hello@rice-ai.com
                  </a>
                </li>
                <li className="flex gap-3 mt-4">
                  <a href="#" className="text-gray-400 hover:text-white transition">
                    <Icon icon="mdi:github" width={20} />
                  </a>
                  <a href="#" className="text-gray-400 hover:text-white transition">
                    <Icon icon="mdi:twitter" width={20} />
                  </a>
                  <a href="#" className="text-gray-400 hover:text-white transition">
                    <Icon icon="mdi:linkedin" width={20} />
                  </a>
                </li>
              </ul>
            </div>
          </div>

          <div className="border-t border-white/10 mt-8 pt-8 text-center text-sm text-gray-400">
            <p>© 2024 Rice AI • Code-Rice • All rights reserved</p>
            <p className="mt-1">Built with GiPT-1 • Powered by Ollama & Stable Diffusion</p>
          </div>
        </div>
      </footer>
    </div>
  );
};

