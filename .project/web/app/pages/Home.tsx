"use client";

import { GradientText, Reveal, Section } from "@rice-mono/ui-kit/lib";

export default function HomePage() {
  return (
    <div className="min-h-screen bg-black text-white">
      {/* HERO fullscreen */}
      <Section className="pt-30 md:pt-30">
        <Reveal className="mx-auto flex min-h-[70dvh] max-w-4xl flex-col items-center justify-center text-center">
          <h1 className="text-4xl font-bold tracking-tight md:text-6xl">
            <span className="gradient-animated-text">Budujemy technologię, która pracuje za Ciebie</span>
          </h1>
          <p className="mt-4 text-gray-300 dark:text-gray-300 text-lg md:text-xl font-semibold font-display tracking-[0.02em]">
            Automatyzacja. AI. Web. Cloud.
          </p>
          {/* Wyróżniony czarny prostokąt — wersja z animowanym pojawianiem (Reveal) */}
          <Reveal
            as="div"
            threshold={0.08}
            effectClass="fade-down-slow"
            className="mt-28 md:mt-40 w-full flex justify-start"
          >
            <div className="relative">
              {/* srebrny cień odbijający się po prawej stronie */}
              <div
                aria-hidden
                className="pointer-events-none absolute right-[-2rem] top-1/2 h-[70%] w-64 -translate-y-1/2 rounded-full bg-gradient-radial from-slate-300/40 via-slate-200/20 to-transparent blur-2xl -z-10"
              />
              <div className="-ml-6 sm:-ml-10 md:-ml-16 lg:-ml-24 xl:-ml-40 2xl:-ml-56 w-[min(56rem,95vw)] lg:w-[52vw] rounded-xl bg-black px-6 py-5 text-left md:px-8 md:py-7 border border-white/5">
                <div className="flex items-center gap-6">
                  <div className="flex-shrink-0 hidden md:block">
                    <img
                      src="/img/agent.png"
                      alt="AI Agent"
                      className="w-32 h-32 lg:w-40 lg:h-40 object-contain opacity-90"
                    />
                  </div>
                  <p
                    className="text-white font-semibold text-xl md:text-2xl leading-relaxed tracking-[0.02em] md:tracking-[0.03em]"
                    style={{ fontFamily: "var(--font-poppins)" }}
                  >
                    Łączymy pasję do kodu z wrażliwością projektową i mocą sztucznej inteligencji, aby tworzyć systemy,
                    które realnie odciążają zespół. Projektujemy doświadczenia, automatyzujemy procesy, porządkujemy
                    dane i przyspieszamy decyzje od designu interfejsu po wydajne, skalowalne mikroserwisy w chmurze.
                    Każde rozwiązanie powstaje pod cele biznesowe i mierzalne efekty, tak by technologia pracowała cicho
                    w tle, a biznes rósł szybciej.
                  </p>
                </div>
              </div>
            </div>
          </Reveal>
          <div className="mt-28 md:mt-32 flex items-center justify-center gap-3">
            <a
              href="#contact"
              className="hero-cta-round hero-cta-pulse"
              role="button"
              aria-label="Skontaktuj się"
              title="Skontaktuj się"
            >
              <span className="hero-cta-round__label">
                Skontaktuj
                <br />
                się
              </span>
            </a>
          </div>
        </Reveal>
      </Section>

      {/* Hero Section */}
      <section className="relative py-32 px-4 overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-b from-amber-900/20 via-black to-black" />
        <div className="max-w-7xl mx-auto text-center relative z-10">
          <Reveal>
            <h1 className="text-6xl md:text-7xl font-bold mb-6">
              <GradientText>RICE</GradientText>
            </h1>
            <p className="text-xl md:text-2xl text-gray-400 mb-8">Revolutionary Intelligence & Cognitive Engineering</p>
            <p className="text-lg text-gray-500 max-w-3xl mx-auto">
              Nowoczesna firma technologiczna specjalizująca się w sztucznej inteligencji, 
              web development, blockchain i cloud computing. Tworzymy rozwiązania, które napędzają biznes.
            </p>
          </Reveal>
        </div>
      </section>

      {/* Features */}
      <section className="py-20 px-4">
        <div className="max-w-7xl mx-auto">
          <Reveal>
            <h2 className="text-4xl font-bold text-center mb-12">
              <GradientText>Nasze Usługi</GradientText>
            </h2>
          </Reveal>

          <div className="grid md:grid-cols-3 gap-8">
            <Reveal delay={0.1}>
              <div className="bg-gradient-to-br from-cyan-900/30 to-gray-900 p-8 rounded-2xl border border-cyan-500/30">
                <div className="text-5xl mb-4">🤖</div>
                <h3 className="text-2xl font-bold mb-4 text-cyan-400">Sztuczna Inteligencja</h3>
                <p className="text-gray-400">
                  Wdrażamy modele AI i machine learning, które automatyzują procesy, analizują dane i wspierają decyzje biznesowe.
                </p>
              </div>
            </Reveal>

            <Reveal delay={0.2}>
              <div className="bg-gradient-to-br from-purple-900/30 to-gray-900 p-8 rounded-2xl border border-purple-500/30">
                <div className="text-5xl mb-4">💻</div>
                <h3 className="text-2xl font-bold mb-4 text-purple-400">Web & Mobile</h3>
                <p className="text-gray-400">
                  Tworzymy nowoczesne aplikacje web i mobile z pięknym UI/UX, które użytkownicy uwielbiają.
                </p>
              </div>
            </Reveal>

            <Reveal delay={0.3}>
              <div className="bg-gradient-to-br from-amber-900/30 to-gray-900 p-8 rounded-2xl border border-amber-500/30">
                <div className="text-5xl mb-4">☁️</div>
                <h3 className="text-2xl font-bold mb-4 text-amber-400">Cloud & DevOps</h3>
                <p className="text-gray-400">
                  Budujemy skalowalną infrastrukturę cloud, automatyzujemy deployment i monitorujemy aplikacje 24/7.
                </p>
              </div>
            </Reveal>
          </div>
        </div>
      </section>
    </div>
  );
}
