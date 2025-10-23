import React from 'react'
import Section from '../../../components/Section'
import Link from 'next/link'

interface PageProps { params: { slug: string } }

const content: Record<string, { title: string; body: string; tech: string[] }> = {
  'ai-chatbot': { title: 'AI Chatbot dla e-commerce', body: 'Agent konwersacyjny zwiększający konwersję i satysfakcję klientów.', tech: ['Next.js','LangChain','Vector DB'] },
  'erp-integration': { title: 'Integracja ERP', body: 'Automatyzacja B2B, synchronizacja stanów i fakturowanie.', tech: ['Go','Python','GraphQL'] },
  'mobile-analytics': { title: 'Mobile analytics', body: 'Aplikacja mobilna i panel w czasie rzeczywistym.', tech: ['Flutter','gRPC','K8s'] },
}

export default function ProjectPage({ params }: PageProps) {
  const proj = content[params.slug]
  if (!proj) return (
    <Section>
      <h1 className="text-2xl font-bold">Projekt nie znaleziony</h1>
      <Link className="mt-4 inline-block text-cyan-300 hover:text-cyan-200" href="/portfolio">← Wróć do portfolio</Link>
    </Section>
  )
  return (
    <Section>
      <Link className="text-cyan-300 hover:text-cyan-200" href="/portfolio">← Portfolio</Link>
      <div className="mt-6 grid items-start gap-8 md:grid-cols-2">
        <div>
          <h1 className="font-display text-4xl font-bold">{proj.title}</h1>
          <p className="mt-4 text-slate-300">{proj.body}</p>
          <div className="mt-6 flex flex-wrap gap-2">
            {proj.tech.map(t => (
              <span key={t} className="rounded-md border border-white/10 bg-white/5 px-2 py-1 text-xs text-slate-300">{t}</span>
            ))}
          </div>
        </div>
        <div className="rounded-xl border border-white/10 bg-white/5 p-8">
          <div className="h-64 w-full rounded-lg bg-gradient-to-br from-cyan-500/20 to-purple-600/20" />
        </div>
      </div>
    </Section>
  )
}
