import React from 'react'
import Section from '../components/Section'
import GradientText from '../components/GradientText'
import { Button } from '@web/components/ui/Button'
import { Card } from '@web/components/ui/Card'
import { Cpu, Cog, Network, Cloud, ShieldCheck, Award } from 'lucide-react'
import ContactForm from '../components/ContactForm'
import Reveal from '../components/Reveal'
import LogoWall from '../components/LogoWall'

export default function HomePage() {
  return (
    <>
      {/* HERO fullscreen */}
      <Section className="pt-24 md:pt-36">
        <Reveal className="mx-auto flex min-h-[70dvh] max-w-4xl flex-col items-center justify-center text-center">
          <h1 className="text-4xl font-bold tracking-tight md:text-6xl">
            <span className="gradient-text">Budujemy technologię, która pracuje za Ciebie</span>
          </h1>
          <p className="mt-4 text-base text-slate-300 md:text-lg">Automatyzacja. AI. Web. Cloud.</p>
          <p className="mt-5 max-w-2xl text-slate-300">
            Łączymy pasję do kodu z projektowaniem i sztuczną inteligencją, tworząc rozwiązania idealnie dopasowane do potrzeb biznesu.
          </p>
          <div className="mt-8 flex items-center justify-center gap-3">
            <a href="#contact"><Button size="lg" variant="outline">Skontaktuj się</Button></a>
          </div>
        </Reveal>
      </Section>

      {/* CO ROBIMY */}
      <Section id="co-robimy" className="pt-0">
        <div className="mb-8 text-center">
          <h2 className="text-3xl font-semibold gradient-text">Co robimy</h2>
        </div>
        <Reveal className="grid gap-6 md:grid-cols-4">
          <Card title="Aplikacje webowe" className="glass">
            <div className="mb-3 text-slate-200"><Cpu size={18} /></div>
            <p className="text-slate-300">Nowoczesne UI z SSR, dostępnością i świetną wydajnością.</p>
          </Card>
          <Card title="Automatyzacja" className="glass">
            <div className="mb-3 text-slate-200"><Cog size={18} /></div>
            <p className="text-slate-300">Usprawniamy procesy, oszczędzając czas i koszty.</p>
          </Card>
          <Card title="Integracje AI" className="glass">
            <div className="mb-3 text-slate-200"><Network size={18} /></div>
            <p className="text-slate-300">Chatboty, RAG, analityka – realna wartość dla zespołów.</p>
          </Card>
          <Card title="Chmura" className="glass">
            <div className="mb-3 text-slate-200"><Cloud size={18} /></div>
            <p className="text-slate-300">Skalowalna infrastruktura: Docker, Kubernetes, CI/CD.</p>
          </Card>
        </Reveal>
      </Section>

      {/* DLACZEGO MY */}
      <Section className="pt-0">
        <div className="mb-8 text-center">
          <h2 className="text-3xl font-semibold gradient-text">Dlaczego my</h2>
        </div>
        <Reveal className="grid gap-6 md:grid-cols-3">
          <Card className="glass" title="Bezpieczeństwo i zgodność">
            <div className="mb-2 text-slate-200"><ShieldCheck size={18} /></div>
            <p className="text-slate-300">DevSecOps, audyty, najlepsze praktyki – bezpieczeństwo danych ponad wszystko.</p>
          </Card>
          <Card className="glass" title="Jakość i doświadczenie">
            <div className="mb-2 text-slate-200"><Award size={18} /></div>
            <p className="text-slate-300">Dostarczamy projekty, które wytrzymują próbę czasu i wzrostu.</p>
          </Card>
          <Card className="glass" title="Partnerskie podejście">
            <p className="text-slate-300">Pracujemy blisko biznesu. Transparentnie, iteracyjnie, odpowiedzialnie.</p>
          </Card>
        </Reveal>
      </Section>

      {/* ZAUFALI NAM */}
      <Section className="pt-0">
        <div className="mb-8 text-center">
          <h2 className="text-3xl font-semibold gradient-text">Zaufali nam</h2>
        </div>
        <Reveal>
          <LogoWall />
        </Reveal>
      </Section>

      {/* CTA */}
      <Section className="pt-0">
        <div className="rounded-xl border border-white/10 bg-white/5 p-8 text-center">
          <h3 className="text-2xl font-semibold gradient-text">Zacznijmy projekt już dziś</h3>
          <p className="mt-2 text-slate-300">Napisz do nas, aby omówić wyzwanie i szybki plan działania.</p>
          <div className="mt-4">
            <a href="#contact"><Button variant="outline">Otwórz formularz</Button></a>
          </div>
        </div>
      </Section>

      {/* CONTACT */}
      <Section id="contact" className="pt-0">
        <div className="mx-auto max-w-3xl">
          <div className="mb-6 text-center">
            <h2 className="text-3xl font-semibold gradient-text">Kontakt</h2>
          </div>
          <ContactForm />
        </div>
      </Section>
    </>
  )
}
