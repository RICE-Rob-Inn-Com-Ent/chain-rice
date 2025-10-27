"use client";
import React, { useState } from "react";
import { Input } from "../atoms/Input";
import { Textarea } from "../atoms/Textarea";
import { Button } from "../atoms/Button";

export default function ContactForm() {
  const [status, setStatus] = useState<"idle" | "sending" | "success" | "error">("idle");
  const [error, setError] = useState<string | null>(null);

  async function onSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    const formData = new FormData((e as any).currentTarget);
    setStatus("sending");
    setError(null);
    try {
      const res = await fetch("/api/contact", {
        method: "POST",
        body: JSON.stringify({
          name: formData.get("name"),
          email: formData.get("email"),
          message: formData.get("message"),
        }),
        headers: { "Content-Type": "application/json" },
      });
      if (!res.ok) throw new Error("Błąd wysyłki");
      setStatus("success");
    } catch (e: any) {
      setError(e.message ?? "Wystąpił błąd");
      setStatus("error");
    }
  }

  return (
    <form
      onSubmit={onSubmit}
      className="animate-fade-in grid gap-6 rounded-2xl border border-white/10 bg-white/5 p-6 text-slate-100 shadow-[0_20px_70px_rgba(0,0,0,0.5)] backdrop-blur-sm md:p-8"
    >
      <div className="grid gap-5 md:grid-cols-2">
        <Input name="name" label="Imię i nazwisko" floating neutralFocus required />
        <Input name="email" type="email" label="E-mail" floating neutralFocus required />
      </div>
      <Textarea name="message" label="Wiadomość" floating neutralFocus rows={5} required />
      {error && <div className="text-sm text-rose-400">{error}</div>}
      <div className="flex items-center justify-end">
        <Button type="submit" size="lg" variant="gradient" className="rounded-full px-6">
          {status === "sending" ? "Wysyłanie…" : "Wyślij wiadomość"}
        </Button>
      </div>
      {status === "success" && (
        <div className="rounded-md border border-emerald-400/40 bg-emerald-400/10 p-3 text-emerald-200">
          Dziękujemy! Skontaktujemy się z Tobą wkrótce.
        </div>
      )}
    </form>
  );
}
