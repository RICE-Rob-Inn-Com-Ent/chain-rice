import React from 'react'
import Section from '../../components/Section'
import ContactForm from '../../components/ContactForm'

export const metadata = { title: 'Kontakt — RICE' }

export default function ContactPage() {
  return (
    <Section>
      <div className="grid gap-10 md:grid-cols-2">
        <div>
          <h1 className="font-display text-4xl font-bold">Kontakt</h1>
          <p className="mt-4 text-slate-300">Napisz do nas — odpowiemy w 24h.</p>
          <div className="mt-6">
            <ContactForm />
          </div>
        </div>
        <div className="space-y-4">
          <div className="rounded-xl border border-white/10 bg-white/5 p-6">
            <div className="text-sm text-slate-300">E-mail</div>
            <div className="text-slate-100">hello@rice.dev</div>
          </div>
          <div className="rounded-xl border border-white/10 bg-white/5 p-6">
            <div className="text-sm text-slate-300">Telefon</div>
            <div className="text-slate-100">+48 000 000 000</div>
          </div>
          <div className="rounded-xl border border-white/10 bg-white/5 p-6">
            <div className="text-sm text-slate-300">Adres</div>
            <div className="text-slate-100">Warszawa, Polska</div>
          </div>
          <div className="rounded-xl border border-white/10 bg-white/5 p-6">
            <div className="text-sm text-slate-300">Linki</div>
            <div className="mt-1 flex gap-3 text-cyan-300">
              <a className="hover:text-cyan-200" href="#">GitHub</a>
              <a className="hover:text-cyan-200" href="#">LinkedIn</a>
              <a className="hover:text-cyan-200" href="#">YouTube</a>
            </div>
          </div>
        </div>
      </div>
    </Section>
  )
}
