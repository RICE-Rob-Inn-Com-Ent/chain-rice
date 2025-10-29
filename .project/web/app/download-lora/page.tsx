"use client";

import React from "react";
import { Section, Button } from "@rice-mono/ui-kit/lib";

export default function DownloadLoraPage() {
  return (
    <Section>
      <div className="mx-auto max-w-3xl text-center">
        <h1 className="text-4xl font-bold gradient-text">Pobierz swoje modele LoRA</h1>
        <p className="mt-3 text-slate-300">
          Przygotujemy paczkę Twoich modeli LoRA do pobrania wraz z instrukcją użycia. Skonfiguruj modele i
          dostosuj je do swojego procesu – otrzymasz gotowy artefakt i przykłady kodu.
        </p>
      </div>

      <div className="mx-auto mt-8 max-w-2xl rounded-xl border border-white/10 bg-white/5 p-6">
        <ol className="list-decimal space-y-3 pl-6 text-slate-300">
          <li>Wyślij nam krótką specyfikację: cel, domena, przykładowe dane (jeśli masz).</li>
          <li>Dobierzemy architekturę i parametry fine-tuningu oraz weryfikacji jakości.</li>
          <li>Otrzymasz link do bezpiecznego pobrania swoich modeli LoRA i guide do integracji.</li>
        </ol>
        <div className="mt-6 flex items-center justify-center gap-3">
          <a href="#contact">
            <Button variant="outline" size="sm">Skontaktuj się</Button>
          </a>
          <a href="#pricing">
            <Button variant="outline" size="sm">Zobacz cennik</Button>
          </a>
        </div>
        <p className="mt-3 text-center text-xs text-slate-400">
          API do automatycznego pobierania będzie dostępne wkrótce. W tej chwili realizujemy zamówienia ręcznie.
        </p>
      </div>
    </Section>
  );
}
