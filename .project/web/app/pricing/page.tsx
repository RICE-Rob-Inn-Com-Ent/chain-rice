import React from 'react'
import Section from '../../components/Section'
import { Button } from '@web/components/ui/Button'
import PricingCalculator from '../../components/PricingCalculator'

export const metadata = { title: 'Cennik — RICE' }

export default function PricingPage() {
  return (
    <>
      <Section>
        <div className="mx-auto max-w-3xl text-center">
          <h1 className="text-4xl font-bold gradient-text">Cennik</h1>
          <p className="mt-3 text-slate-300">Przejrzyste pakiety oraz szybki kalkulator szacunkowy.</p>
        </div>
        <div className="mt-10 grid gap-6 md:grid-cols-3">
          <div className="rounded-xl border border-white/10 bg-white/5 p-6">
            <div className="text-sm text-slate-400">Start</div>
            <div className="mt-2 text-3xl font-semibold">4 900 PLN</div>
            <ul className="mt-4 space-y-2 text-sm text-slate-300">
              <li>Do 5 podstron</li>
              <li>Formularz kontaktowy</li>
              <li>Hosting i wdrożenie</li>
            </ul>
            <div className="mt-5"><Button variant="outline" size="sm">Wybierz</Button></div>
          </div>
          <div className="rounded-xl border border-white/10 bg-white/5 p-6">
            <div className="text-sm text-slate-400">Pro</div>
            <div className="mt-2 text-3xl font-semibold">9 900 PLN</div>
            <ul className="mt-4 space-y-2 text-sm text-slate-300">
              <li>SSR/SEO, CMS</li>
              <li>Integracje (2)</li>
              <li>Analityka i monitoring</li>
            </ul>
            <div className="mt-5"><Button variant="outline" size="sm">Wybierz</Button></div>
          </div>
          <div className="rounded-xl border border-white/10 bg-white/5 p-6">
            <div className="text-sm text-slate-400">Enterprise</div>
            <div className="mt-2 text-3xl font-semibold">Indywidualnie</div>
            <ul className="mt-4 space-y-2 text-sm text-slate-300">
              <li>Architektura i automatyzacja</li>
              <li>Integracje AI</li>
              <li>Wsparcie SLA</li>
            </ul>
            <div className="mt-5"><a href="#contact"><Button variant="outline" size="sm">Porozmawiajmy</Button></a></div>
          </div>
        </div>

        <div className="mt-12">
          <PricingCalculator />
        </div>
      </Section>
    </>
  )
}
