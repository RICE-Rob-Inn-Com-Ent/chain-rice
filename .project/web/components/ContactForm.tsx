"use client";
import React, { useState } from 'react'
import { Input } from '@web/components/ui/Input'
import { Textarea } from '@web/components/ui/Textarea'
import { Button } from '@web/components/ui/Button'

export default function ContactForm() {
  const [status, setStatus] = useState<'idle'|'sending'|'success'|'error'>('idle')
  const [error, setError] = useState<string | null>(null)

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault()
    const formData = new FormData((e as any).currentTarget)
    setStatus('sending')
    setError(null)
    try {
      const res = await fetch('/api/contact', {
        method: 'POST',
        body: JSON.stringify({
          name: formData.get('name'),
          email: formData.get('email'),
          message: formData.get('message'),
        }),
        headers: { 'Content-Type': 'application/json' }
      })
      if (!res.ok) throw new Error('Błąd wysyłki')
      setStatus('success')
    } catch (e: any) {
      setError(e.message ?? 'Wystąpił błąd')
      setStatus('error')
    }
  }

  return (
  <form onSubmit={onSubmit} className="grid gap-4 rounded-xl border border-white/10 bg-white p-6 text-slate-900">
      <div className="grid gap-4 md:grid-cols-2">
        <Input name="name" label="Imię i nazwisko" placeholder="Jan Kowalski" className="bg-black text-white placeholder:text-slate-400 border-black/20" required />
        <Input name="email" type="email" label="E-mail" placeholder="jan@firma.com" className="bg-black text-white placeholder:text-slate-400 border-black/20" required />
      </div>
      <Textarea name="message" label="Wiadomość" placeholder="Opowiedz nam o swoim wyzwaniu..." className="bg-black text-white placeholder:text-slate-400 border-black/20" rows={5} required />
      {error && <div className="text-sm text-red-600">{error}</div>}
      <div className="flex items-center justify-end">
        <Button type="submit" disabled={status==='sending'}>
          {status==='sending' ? 'Wysyłanie…' : 'Wyślij wiadomość'}
        </Button>
      </div>
      {status==='success' && (
        <div className="rounded-md border border-emerald-600/30 bg-emerald-600/10 p-3 text-emerald-700">
          Dziękujemy! Skontaktujemy się z Tobą wkrótce.
        </div>
      )}
    </form>
  )
}
