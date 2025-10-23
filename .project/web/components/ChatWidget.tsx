"use client";
import React, { useEffect, useRef, useState } from 'react'
import { MessageSquare, X } from 'lucide-react'
import { Button } from '@web/components/ui/Button'

type ChatMsg = { role: 'user' | 'assistant'; text: string }

const ChatWidget: React.FC = () => {
  const [open, setOpen] = useState(false)
  const [messages, setMessages] = useState<ChatMsg[]>([
    { role: 'assistant', text: 'Cześć! Jestem asystentem RICE. Pomogę w kontakcie, wycenie lub pytaniach technicznych.' },
  ])
  const [input, setInput] = useState('')
  const viewportRef = useRef<HTMLDivElement | null>(null)

  useEffect(() => {
    viewportRef.current?.scrollTo({ top: viewportRef.current.scrollHeight })
  }, [messages, open])

  function send()
  {
    if (!input.trim()) return
    const userMsg: ChatMsg = { role: 'user', text: input.trim() }
  setMessages((m: any) => [...m, userMsg])
    setInput('')
    setTimeout(() => {
      const reply: ChatMsg = { role: 'assistant', text: 'Dzięki! Przekazałem szczegóły. Odezwiemy się wkrótce z wyceną / propozycją.' }
  setMessages((m: any) => [...m, reply])
    }, 400)
  }

  return (
    <>
      {/* Floating button */}
      <button
        aria-label="Otwórz czat"
        onClick={() => setOpen(true)}
        className="fixed bottom-5 right-5 z-50 h-12 w-12 rounded-full bg-white text-black shadow-lg ring-1 ring-white/20 hover:scale-105 smooth"
      >
        <MessageSquare className="mx-auto" size={22} />
      </button>

      {/* Panel */}
      {open && (
        <div className="fixed bottom-20 right-5 z-50 w-[360px] overflow-hidden rounded-xl border border-white/10 bg-black/90 backdrop-blur-md">
          <div className="flex items-center justify-between border-b border-white/10 px-3 py-2">
            <div className="text-sm gradient-text">Asystent RICE</div>
            <button aria-label="Zamknij" onClick={() => setOpen(false)} className="text-slate-300 hover:text-white">
              <X size={18} />
            </button>
          </div>
          <div ref={viewportRef} className="max-h-80 overflow-y-auto p-3">
            {messages.map((m: any, i: number) => (
              <div key={i} className={`mb-2 flex ${m.role === 'user' ? 'justify-end' : 'justify-start'}`}>
                <div className={`${m.role === 'user' ? 'bg-white text-black' : 'bg-white/5 text-slate-100'} rounded-md px-3 py-2 text-sm`}>{m.text}</div>
              </div>
            ))}
          </div>
          <div className="flex items-center gap-2 border-t border-white/10 p-3">
            <input
              value={input}
              onChange={(e: any) => setInput(e.target.value)}
              onKeyDown={(e: any) => e.key === 'Enter' && (e.preventDefault(), send())}
              placeholder="Napisz wiadomość..."
              className="h-10 flex-1 rounded-md border border-white/10 bg-white/5 px-3 text-slate-100 placeholder:text-slate-400 outline-none focus:border-white/30"
            />
            <Button onClick={send} size="sm" variant="outline">Wyślij</Button>
          </div>
        </div>
      )}
    </>
  )
}

export default ChatWidget
