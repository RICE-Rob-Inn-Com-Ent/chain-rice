import Section from "@rice-mono/ui-kit/lib/base/Section";
import { Button } from "@rice-mono/ui-kit/lib/base/Button";
import Card from "@rice-mono/ui-kit/lib/base/Card";
import PricingCalculator from "@rice-mono/ui-kit/lib/organisms/PricingCalculator";
import ContactForm from "@rice-mono/ui-kit/lib/organisms/ContactForm";

export default function Page() {
  return (
    <div className="flex min-h-screen flex-col bg-black text-white">
      {/* Header */}
      <header className="sticky top-0 z-50 border-b border-white/10 bg-black/70 backdrop-blur-md">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-4">
          <a href="#" className="font-extrabold text-lg gradient-logo-text">RICE</a>
          <nav className="nav-capsule hidden gap-1 rounded-full p-1 md:flex">
            <a href="#features" className="nav-item no-nav-underline">Funkcje</a>
            <a href="#pricing" className="nav-item no-nav-underline">Cennik</a>
            <a href="#contact" className="nav-item no-nav-underline">Kontakt</a>
          </nav>
          <a href="#contact" className="cta-outline"><span className="cta-inner">Porozmawiajmy</span></a>
        </div>
      </header>

      {/* Main */}
      <main className="flex-1">
        {/* HERO */}
        <Section>
          <div className="mx-auto max-w-3xl text-center">
            <h1 className="text-4xl font-extrabold md:text-6xl">
              <span className="gradient-animated-text">Marketing IT</span> zasilany AI i automatyzacją
            </h1>
            <p className="mt-4 text-lg text-slate-300">
              Projektujemy i wdrażamy nowoczesne strony, systemy i kampanie. Od strategii po
              implementację – szybko, mierzalnie, skalowalnie.
            </p>
            <div className="mt-8 flex items-center justify-center gap-3">
              <a href="#pricing" className="cta-outline"><span className="cta-inner">Zobacz cennik</span></a>
              <a href="#features" className="cta-neutral"><span className="cta-neutral__inner">Co oferujemy</span></a>
            </div>
          </div>
        </Section>

        {/* FEATURES */}
        <Section id="features">
          <div className="mx-auto mb-8 max-w-3xl text-center">
            <h2 className="text-3xl font-bold gradient-text">Co dostarczamy</h2>
            <p className="mt-2 text-slate-300">Komplet usług dla marketingu IT – technologia, content i analityka.</p>
          </div>
          <div className="grid gap-6 md:grid-cols-3">
            {[
              { title: "Strony i landing pages", desc: "Next.js, SSR/SEO, performance 90+" },
              { title: "Integracje AI", desc: "Chaty, generatory treści, rekomendacje" },
              { title: "Automatyzacja", desc: "Zbieranie leadów, scoring, CRM, webhooki" },
            ].map((f) => (
              <Card key={f.title} title={f.title}>
                <p className="mt-1 text-slate-300">{f.desc}</p>
              </Card>
            ))}
          </div>
        </Section>

        {/* PRICING */}
        <Section id="pricing">
          <div className="mx-auto max-w-3xl text-center">
            <h2 className="text-3xl font-bold gradient-text">Cennik</h2>
            <p className="mt-3 text-slate-300">Przejrzyste pakiety oraz szybki kalkulator szacunkowy.</p>
          </div>

          <div className="mt-10 grid gap-6 md:grid-cols-3">
            {[{name:"Start", price:"4 900 PLN", features:["Do 5 podstron","Formularz kontaktowy","Hosting i wdrożenie"]},
              {name:"Pro", price:"9 900 PLN", features:["SSR/SEO, CMS","Integracje (2)","Analityka i monitoring"]},
              {name:"Enterprise", price:"Indywidualnie", features:["Architektura i automatyzacja","Integracje AI","Wsparcie SLA"]}
            ].map((p)=> (
              <Card key={p.name}>
                <div className="text-sm text-slate-400">{p.name}</div>
                <div className="mt-2 text-3xl font-semibold">{p.price}</div>
                <ul className="mt-4 space-y-2 text-sm text-slate-300">
                  {p.features.map((it)=> (<li key={it}>• {it}</li>))}
                </ul>
                <div className="mt-5">
                  <Button variant="outline" size="sm">Wybierz</Button>
                </div>
              </Card>
            ))}
          </div>

          <div className="mt-12">
            <PricingCalculator />
          </div>
        </Section>

        {/* CONTACT */}
        <Section id="contact">
          <div className="mx-auto max-w-xl text-center">
            <h2 className="text-3xl font-bold gradient-text">Porozmawiajmy o Twoich celach</h2>
            <p className="mt-3 text-slate-300">Zostaw kontakt – przygotujemy propozycję w 48h.</p>
          </div>
          <div className="mx-auto max-w-xl">
            <ContactForm />
          </div>
        </Section>
      </main>

      {/* Footer */}
      <footer className="border-t border-white/10">
        <div className="mx-auto flex max-w-7xl flex-col items-center justify-between gap-4 px-6 py-6 md:flex-row">
          <div className="text-sm text-slate-400">© <span suppressHydrationWarning>{new Date().getFullYear()}</span> RICE. Wszelkie prawa zastrzeżone.</div>
          <nav className="flex items-center gap-4 text-sm text-slate-400">
            <a className="link-underline" href="#features">Funkcje</a>
            <a className="link-underline" href="#pricing">Cennik</a>
            <a className="link-underline" href="#contact">Kontakt</a>
          </nav>
        </div>
      </footer>
    </div>
  );
}
