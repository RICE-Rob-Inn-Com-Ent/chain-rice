import React from "react";
import Section from "@/lib/atoms/Section";
import Reveal from "@/lib/atoms/Reveal";

const team = [
  { name: "Anna", role: "Product Lead" },
  { name: "Michał", role: "Full‑stack Engineer" },
  { name: "Ewa", role: "ML Engineer" },
  { name: "Krzysztof", role: "DevOps" },
];

export default function TeamPage() {
  return (
    <Section>
      <h1 className="font-display text-4xl font-bold gradient-text">Zespół</h1>
      <p className="mt-4 text-slate-300">Poznaj ludzi stojących za produktami.</p>
      <Reveal className="mt-8 grid gap-6 sm:grid-cols-2 md:grid-cols-4">
        {team.map((m) => (
          <div key={m.name} className="glass rounded-xl p-5 text-center">
            <div className="mx-auto h-20 w-20 rounded-full bg-white/10" />
            <div className="mt-3 font-semibold text-slate-100">{m.name}</div>
            <div className="text-sm text-slate-300">{m.role}</div>
          </div>
        ))}
      </Reveal>
    </Section>
  );
}
