"use client";

import { useState, useEffect } from "react";
import { useRouter, usePathname } from "next/navigation";
import Link from "next/link";
import { Phone, Mail, MapPin, Clock, CheckCircle2, Sparkles, Shield, Heart, Award, Menu, X, LogOut } from "lucide-react";

interface User {
  id: string;
  email: string;
  display_name: string;
  role: string;
}

export default function MainPage() {
  const router = useRouter();
  const pathname = usePathname();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let mounted = true;

    // If we're on base domain (ceramix.ltd), middleware already handled redirect
    // This page should only be accessible on base domain for unauthenticated users
    if (typeof window === "undefined") {
      // SSR - middleware will handle redirects
      setLoading(false);
      setUser(null);
      return;
    }

    const host = window.location.hostname.toLowerCase();
    const isPanel =
      host === "panel.ceramix.ltd" ||
      host.startsWith("panel.") ||
      host === "localhost" ||
      host.includes("localhost:");

    // If we're on panel domain, middleware should have redirected to /me
    // If we're here, something went wrong - but don't check auth on marketing site
    if (!isPanel) {
      setLoading(false);
      setUser(null);
      return; // Show marketing page - middleware handles auth redirects
    }

    // Don't redirect if we're already on an admin page or account page
    if (pathname?.startsWith("/admin") || pathname?.startsWith("/account")) {
      setLoading(false);
      return;
    }

    // Set timeout to prevent infinite loading
    const timeout = setTimeout(() => {
      if (mounted) {
        console.warn("Auth check timeout, showing page");
        setLoading(false);
      }
    }, 3000); // 3 second timeout

    // Auth check - 401 means user is not logged in (normal, not an error)
    // Only perform on panel domain, not on main marketing site
    const authCheck = async () => {
      try {
        const response = await fetch("/api/auth/me", {
          credentials: "include",
          headers: { "Content-Type": "application/json" },
        });

        clearTimeout(timeout);
        if (!mounted) return;

        // Handle 401 first - it's expected, not an error - silently return
        if (response.status === 401) {
          setUser(null);
          setLoading(false);
          return;
        }

        // Only throw for non-401 errors
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }

        const data = await response.json();
        if (!mounted || !data) return;

        // Don't redirect if we're already on an admin page or account page
        if (pathname?.startsWith("/admin") || pathname?.startsWith("/account")) {
          setLoading(false);
          return;
        }

        if (data.user) {
          // Redirect based on role immediately
          let redirectUrl = "/account";
          if (data.user.role === "superadmin" || data.user.role === "admin") {
            redirectUrl = "/admin";
          } else if (data.user.role === "dentist") {
            redirectUrl = "/admin/appointments";
          }
          // Use window.location for immediate redirect
          window.location.href = redirectUrl;
          return; // Don't update state, we're redirecting
        }
        // User not logged in, show page
        setUser(null);
        setLoading(false);
      } catch (err: any) {
        clearTimeout(timeout);
        if (!mounted) return;

        // 401 is normal - never log it, never throw it - silently handle
        const errText = String(err?.message || err || "");
        const is401 =
          errText.includes("401") ||
          errText.toLowerCase().includes("unauthorized");

        // Silently handle 401 - it's expected on public pages
        if (is401) {
          setUser(null);
          setLoading(false);
          return;
        }

        // Only log non-401 errors
        console.error("Error checking auth:", err);
        setUser(null);
        setLoading(false);
      }
    };

    authCheck();

    return () => {
      mounted = false;
      clearTimeout(timeout);
    };
  }, [pathname]);

  const handleLogout = async () => {
    await fetch("/api/auth/logout", { method: "POST" });
    router.refresh();
    setUser(null);
  };

  if (loading) {
    return (
      <main className="min-h-screen bg-[#050505] flex items-center justify-center">
        <div className="text-[#f8f3e7]">Ładowanie...</div>
      </main>
    );
  }

  const services = [
    {
      icon: Sparkles,
      title: "Protetyka",
      description: "Korony, mosty, protezy - przywracamy piękny uśmiech",
      color: "text-[#f6823c]",
    },
    {
      icon: Shield,
      title: "Implantologia",
      description: "Nowoczesne implanty zębowe - trwałe rozwiązanie",
      color: "text-blue-400",
    },
    {
      icon: Heart,
      title: "Stomatologia zachowawcza",
      description: "Leczenie próchnicy i zachowanie zdrowych zębów",
      color: "text-green-400",
    },
    {
      icon: Award,
      title: "Ortodoncja",
      description: "Aparaty stałe i ruchome - prosty uśmiech",
      color: "text-purple-400",
    },
  ];

  const features = [
    "Nowoczesny sprzęt",
    "Doświadczony zespół",
    "Bezbolesne leczenie",
    "Dogodne terminy",
    "Obsługa w 3 językach",
    "Przyjazna atmosfera",
  ];

  return (
    <main className="min-h-screen bg-[#050505]">
      {/* Navigation */}
      <nav className="fixed top-0 w-full z-50 bg-[#050505]/80 backdrop-blur-md border-b border-[#eb520a]/20">
        <div className="container mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 bg-gradient-to-br from-[#eb520a] to-[#cb3906] rounded-lg flex items-center justify-center">
                <Sparkles className="w-6 h-6 text-white" />
              </div>
              <span className="text-2xl font-display font-bold text-[#f8f3e7]">Ceramix</span>
            </div>
            <div className="hidden md:flex items-center gap-8">
              <Link href="#uslugi" className="text-[#f8f3e7]/80 hover:text-[#f6823c] transition-colors">Usługi</Link>
              <Link href="#o-nas" className="text-[#f8f3e7]/80 hover:text-[#f6823c] transition-colors">O nas</Link>
              <Link href="#kontakt" className="text-[#f8f3e7]/80 hover:text-[#f6823c] transition-colors">Kontakt</Link>
              {user ? (
                <>
                  <span className="text-[#f8f3e7]/80">{user.display_name}</span>
                  <button
                    onClick={handleLogout}
                    className="btn-secondary text-sm flex items-center gap-2"
                  >
                    <LogOut className="w-4 h-4" />
                    Wyloguj
                  </button>
                </>
              ) : (
                <>
                  <Link href="/sign-in" className="text-[#f8f3e7]/80 hover:text-[#f6823c] transition-colors">Zaloguj</Link>
                  <Link href="/sign-up" className="btn-secondary text-sm">Rejestracja</Link>
                </>
              )}
            </div>
            <button
              className="md:hidden text-[#f8f3e7] p-2"
              onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
              aria-label="Toggle menu"
            >
              {mobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
            </button>
          </div>
        </div>
        {/* Mobile Menu */}
        {mobileMenuOpen && (
          <div className="md:hidden border-t border-[#eb520a]/20 bg-[#050505]/95 backdrop-blur-md">
            <div className="px-6 py-4 space-y-4">
              <Link
                href="#uslugi"
                className="block text-[#f8f3e7]/80 hover:text-[#f6823c] transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Usługi
              </Link>
              <Link
                href="#o-nas"
                className="block text-[#f8f3e7]/80 hover:text-[#f6823c] transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                O nas
              </Link>
              <Link
                href="#kontakt"
                className="block text-[#f8f3e7]/80 hover:text-[#f6823c] transition-colors"
                onClick={() => setMobileMenuOpen(false)}
              >
                Kontakt
              </Link>
              {user ? (
                <div className="pt-4 border-t border-[#f8f3e7]/10 space-y-3">
                  <div className="text-[#f8f3e7]/80 mb-2">{user.display_name}</div>
                  <button
                    onClick={() => {
                      handleLogout();
                      setMobileMenuOpen(false);
                    }}
                    className="w-full btn-secondary text-center flex items-center justify-center gap-2"
                  >
                    <LogOut className="w-4 h-4" />
                    Wyloguj
                  </button>
                </div>
              ) : (
                <div className="pt-4 border-t border-[#f8f3e7]/10 space-y-3">
                  <Link
                    href="/sign-in"
                    className="block text-[#f8f3e7] hover:text-[#f6823c] transition-colors font-medium"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    Zaloguj się
                  </Link>
                  <Link
                    href="/sign-up"
                    className="block btn-secondary text-center"
                    onClick={() => setMobileMenuOpen(false)}
                  >
                    Rejestracja
                  </Link>
                </div>
              )}
            </div>
          </div>
        )}
      </nav>

      {/* Hero Section */}
      <section className="relative min-h-screen flex items-center justify-center pt-20 overflow-hidden">
        {/* Background effects */}
        <div className="absolute inset-0" style={{
          background: 'radial-gradient(circle at top, rgba(132,37,12,0.55), rgba(5,5,5,0.95))'
        }} />
        <div className="absolute inset-0 opacity-20" style={{ 
          backgroundImage: 'linear-gradient(rgba(255,255,255,0.04) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.04) 1px, transparent 1px)',
          backgroundSize: '50px 50px'
        }} />
        
        {/* Floating particles */}
        <div className="absolute inset-0 overflow-hidden">
          {[...Array(15)].map((_, i) => (
            <div
              key={i}
              className="absolute w-1 h-1 bg-[#f6823c]/30 rounded-full animate-pulse"
              style={{
                left: `${Math.random() * 100}%`,
                top: `${Math.random() * 100}%`,
                animationDelay: `${Math.random() * 3}s`,
              }}
            />
          ))}
        </div>

        <div className="relative z-10 container mx-auto px-6 text-center">
          <div className="mb-6 inline-block">
            <span className="px-4 py-2 bg-[#eb520a]/20 border border-[#eb520a]/50 rounded-full text-[#fdb076] text-sm font-semibold">
              Klinika Stomatologiczna Bielsko-Biała
            </span>
          </div>
          
          <h1 className="text-6xl md:text-8xl font-display font-bold mb-6 text-transparent bg-clip-text bg-gradient-to-r from-[#f8f3e7] via-[#fed0a8] to-[#f6823c]">
            Twój piękny uśmiech<br />to nasza pasja
          </h1>
          
          <p className="text-xl md:text-2xl text-[#f8f3e7]/80 mb-12 max-w-2xl mx-auto font-light">
            Profesjonalna opieka stomatologiczna w przyjaznej atmosferze. 
            Dbamy o zdrowie i piękno Twojego uśmiechu.
          </p>

          <div className="flex flex-col sm:flex-row gap-4 justify-center items-center">
            <Link href="#rezerwacja" className="btn-primary text-lg">
              Umów wizytę
            </Link>
            <Link href="#uslugi" className="btn-secondary text-lg">
              Poznaj usługi
            </Link>
          </div>

          {/* Quick contact */}
          <div className="mt-16 flex flex-wrap justify-center gap-8 text-[#f8f3e7]/70">
            <div className="flex items-center gap-2">
              <Phone className="w-5 h-5 text-[#f6823c]" />
              <span>+48 33 812 59 82</span>
            </div>
            <div className="flex items-center gap-2">
              <Clock className="w-5 h-5 text-[#f6823c]" />
              <span>Pon-Pt: 8:00-20:00</span>
            </div>
            <div className="flex items-center gap-2">
              <MapPin className="w-5 h-5 text-[#f6823c]" />
              <span>Bielsko-Biała</span>
            </div>
          </div>
        </div>
      </section>

      {/* Services Section */}
      <section id="uslugi" className="py-24 bg-[#0f0f0f]/50">
        <div className="container mx-auto px-6">
          <div className="text-center mb-16">
            <h2 className="text-5xl font-display font-bold mb-4 text-[#f8f3e7]">
              Nasze usługi
            </h2>
            <p className="text-xl text-[#f8f3e7]/70 max-w-2xl mx-auto">
              Kompleksowa opieka stomatologiczna na najwyższym poziomie
            </p>
          </div>

          <div className="grid md:grid-cols-2 lg:grid-cols-4 gap-6">
            {services.map((service, index) => {
              const Icon = service.icon;
              return (
                <div key={index} className="marble-card p-6 hover:border-[#eb520a]/50 transition-all duration-300 group">
                  <div className={`w-12 h-12 ${service.color} mb-4 group-hover:scale-110 transition-transform`}>
                    <Icon className="w-full h-full" />
                  </div>
                  <h3 className="text-xl font-semibold mb-2 text-[#f8f3e7]">{service.title}</h3>
                  <p className="text-[#f8f3e7]/70 text-sm">{service.description}</p>
                </div>
              );
            })}
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-24" style={{
        background: 'radial-gradient(circle at top, rgba(132,37,12,0.55), rgba(5,5,5,0.95))'
      }}>
        <div className="container mx-auto px-6">
          <div className="max-w-4xl mx-auto">
            <h2 className="text-5xl font-display font-bold mb-12 text-center text-[#f8f3e7]">
              Dlaczego Ceramix?
            </h2>
            <div className="grid md:grid-cols-2 gap-6">
              {features.map((feature, index) => (
                <div key={index} className="flex items-center gap-4 marble-card p-6">
                  <CheckCircle2 className="w-6 h-6 text-[#f6823c] flex-shrink-0" />
                  <span className="text-lg text-[#f8f3e7]">{feature}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
      </section>

      {/* About Section */}
      <section id="o-nas" className="py-24 bg-[#0f0f0f]/50">
        <div className="container mx-auto px-6">
          <div className="max-w-4xl mx-auto text-center">
            <h2 className="text-5xl font-display font-bold mb-6 text-[#f8f3e7]">
              O nas
            </h2>
            <p className="text-xl text-[#f8f3e7]/80 leading-relaxed mb-8">
              Ceramix to nowoczesna klinika stomatologiczna w Bielsku-Białej, 
              gdzie łączymy najwyższą jakość leczenia z indywidualnym podejściem do każdego pacjenta.
            </p>
            <p className="text-lg text-[#f8f3e7]/70 leading-relaxed">
              Nasz zespół doświadczonych specjalistów oferuje kompleksową opiekę stomatologiczną 
              w przyjaznej atmosferze. Obsługujemy pacjentów w języku polskim, angielskim i ukraińskim.
            </p>
          </div>
        </div>
      </section>

      {/* Appointment Form Section */}
      <section id="rezerwacja" className="py-24" style={{
        background: 'radial-gradient(circle at top, rgba(132,37,12,0.55), rgba(5,5,5,0.95))'
      }}>
        <div className="container mx-auto px-6">
          <div className="max-w-2xl mx-auto marble-card p-8">
            <h2 className="text-4xl font-display font-bold mb-6 text-center text-[#f8f3e7]">
              Umów wizytę
            </h2>
            <form className="space-y-6">
              <div>
                <label className="block text-[#f8f3e7]/80 mb-2">Imię i nazwisko</label>
                <input
                  type="text"
                  className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a]"
                  placeholder="Jan Kowalski"
                />
              </div>
              <div>
                <label className="block text-[#f8f3e7]/80 mb-2">Telefon</label>
                <input
                  type="tel"
                  className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a]"
                  placeholder="+48 123 456 789"
                />
              </div>
              <div>
                <label className="block text-[#f8f3e7]/80 mb-2">Email</label>
                <input
                  type="email"
                  className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a]"
                  placeholder="jan@example.com"
                />
              </div>
              <div>
                <label className="block text-[#f8f3e7]/80 mb-2">Preferowany termin</label>
                <input
                  type="date"
                  className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a]"
                />
              </div>
              <div>
                <label className="block text-[#f8f3e7]/80 mb-2">Uwagi</label>
                <textarea
                  rows={4}
                  className="w-full px-4 py-3 bg-[#171717]/50 border border-[#f8f3e7]/20 rounded-lg text-[#f8f3e7] focus:outline-none focus:border-[#eb520a]"
                  placeholder="Opisz problem lub preferencje..."
                />
              </div>
              <button type="submit" className="btn-primary w-full text-lg">
                Wyślij zgłoszenie
              </button>
            </form>
          </div>
        </div>
      </section>

      {/* Contact Section */}
      <section id="kontakt" className="py-24 bg-[#0f0f0f]/50">
        <div className="container mx-auto px-6">
          <div className="max-w-4xl mx-auto">
            <h2 className="text-5xl font-display font-bold mb-12 text-center text-[#f8f3e7]">
              Kontakt
            </h2>
            <div className="grid md:grid-cols-3 gap-8">
              <div className="marble-card p-6 text-center">
                <Phone className="w-10 h-10 text-[#f6823c] mx-auto mb-4" />
                <h3 className="text-xl font-semibold mb-2 text-[#f8f3e7]">Telefon</h3>
                <p className="text-[#f8f3e7]/70">+48 33 812 59 82</p>
              </div>
              <div className="marble-card p-6 text-center">
                <Mail className="w-10 h-10 text-[#f6823c] mx-auto mb-4" />
                <h3 className="text-xl font-semibold mb-2 text-[#f8f3e7]">Email</h3>
                <p className="text-[#f8f3e7]/70">kontakt@ceramix.pl</p>
              </div>
              <div className="marble-card p-6 text-center">
                <MapPin className="w-10 h-10 text-[#f6823c] mx-auto mb-4" />
                <h3 className="text-xl font-semibold mb-2 text-[#f8f3e7]">Adres</h3>
                <p className="text-[#f8f3e7]/70">Bielsko-Biała</p>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="py-12 bg-[#050505] border-t border-[#eb520a]/20">
        <div className="container mx-auto px-6 text-center">
          <p className="text-[#f8f3e7]/60">
            © {new Date().getFullYear()} Ceramix. Wszystkie prawa zastrzeżone.
          </p>
        </div>
      </footer>
    </main>
  );
}
