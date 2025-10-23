import React from 'react'
import Section from '../../components/Section'
import Link from 'next/link'

type Project = { slug: string; name: string; summary: string }
const projects: Project[] = [
  { slug: 'ai-chatbot', name: 'AI Chatbot dla e-commerce', summary: 'Obsługa klienta 24/7, rekomendacje i automatyzacja zwrotów.' },
  { slug: 'erp-integration', name: 'Integracja ERP', summary: 'Spójne dane i automatyczny obieg zamówień B2B.' },
  { slug: 'mobile-analytics', name: 'Mobile analytics', summary: 'Aplikacja mobilna z dashboardem w czasie rzeczywistym.' }
]

export const metadata = { title: 'Portfolio — RICE' }

export default function PortfolioPage() {
  return (
    <Section>
      <h1 className="font-display text-4xl font-bold">Portfolio</h1>
      <p className="mt-4 text-slate-300">Wybrane realizacje i koncepcje. Kliknij, aby poznać szczegóły.</p>
      <div className="mt-8 grid gap-6 md:grid-cols-3">
        {projects.map(p => (
          <Link key={p.slug} href={`/portfolio/${p.slug}`} className="rounded-lg border border-white/10 bg-white/5 p-5 transition hover:border-cyan-400/40 hover:shadow-[0_0_25px_rgba(34,211,238,0.25)]">
            <div className="h-28 w-full rounded-md bg-gradient-to-br from-cyan-500/20 to-purple-500/20" />
            <h3 className="mt-4 text-lg font-semibold text-slate-100">{p.name}</h3>
            <p className="text-sm text-slate-300">{p.summary}</p>
          </Link>
        ))}
      </div>
    </Section>
  )
}
