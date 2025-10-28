"use client";

import React from "react";
import { Section, Card, TechStackGrid } from "@rice-mono/ui-kit/lib";

export default function AboutPage() {
  return (
    <>
      <Section>
        <div className="grid items-center gap-10 md:grid-cols-2">
          <div>
            <h1 className="font-display text-4xl font-bold">Kim jesteśmy</h1>
            <p className="mt-4 text-slate-300">
              Budujemy nowoczesne systemy dla biznesu: od aplikacji web i mobile, przez backend i automatyzację, po AI i
              blockchain.
            </p>
            <p className="mt-2 text-slate-300">
              Naszą misją jest łączenie technologii z realnymi potrzebami — prosto, skalowalnie i z wyczuciem estetyki.
            </p>
            <p className="mt-2 text-slate-300">
              Wyróżnia nas pełna odpowiedzialność za produkt i bliska współpraca z klientami.
            </p>
          </div>
          <div className="rounded-xl border border-white/10 bg-white/5 p-8">
            <div className="h-48 w-full rounded-lg bg-gradient-to-br from-cyan-500/20 to-purple-600/20" />
          </div>
        </div>
      </Section>

      <Section className="pt-0">
        <div className="grid gap-6 md:grid-cols-3">
          <Card className="glass neon-hover" title="Automatyzacja procesów">
            <p className="text-slate-300">Integracje, orkiestracja i optymalizacja przepływów pracy.</p>
          </Card>
          <Card className="glass neon-hover" title="Systemy Web & Mobile">
            <p className="text-slate-300">Piękne, szybkie i dostępne interfejsy na każdą platformę.</p>
          </Card>
          <Card className="glass neon-hover" title="AI i Blockchain">
            <p className="text-slate-300">Inteligentne modele, smart kontrakty i bezpieczna infrastruktura.</p>
          </Card>
        </div>
      </Section>

      {/* Tech Stack Section */}
      <Section id="tech-stack" className="pt-0">
        <TechStackGrid
          items={[
            { name: "React", category: "Frontend", icon: "⚛️" },
            { name: "Next.js", category: "Framework", icon: "▲" },
            { name: "TypeScript", category: "Language", icon: "📘" },
            { name: "Tailwind", category: "Styling", icon: "🎨" },
            { name: "Python", category: "Backend", icon: "🐍" },
            { name: "Go", category: "Backend", icon: "🐹" },
            { name: "Docker", category: "DevOps", icon: "🐳" },
            { name: "Kubernetes", category: "DevOps", icon: "☸️" },
          ]}
        />
      </Section>
    </>
  );
}
