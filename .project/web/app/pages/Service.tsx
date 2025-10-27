import React from "react";
import { Section, Card } from "@rice-mono/ui-kit/lib";
import { Cpu, Smartphone, Blocks, Network, Cloud, Database } from "lucide-react";

const services = [
  {
    icon: <Cpu size={18} />,
    title: "Frontend",
    desc: "React, Next.js, Flutter — nowoczesne UI z SSR i świetną wydajnością.",
    tech: ["React", "Next.js", "Tailwind", "Flutter"],
  },
  {
    icon: <Database size={18} />,
    title: "Backend",
    desc: "Python, Go, mikrousługi, GraphQL, event-driven.",
    tech: ["Python", "Go", "CQRS", "GraphQL"],
  },
  {
    icon: <Blocks size={18} />,
    title: "Blockchain",
    desc: "Solidity, CosmWasm, IPFS — Web3 i tokenizacja procesów.",
    tech: ["Solidity", "CosmWasm", "IPFS"],
  },
  {
    icon: <Network size={18} />,
    title: "AI",
    desc: "LangChain, RAG, automatyzacja, agentowe przepływy.",
    tech: ["LangChain", "RAG", "Vector DB"],
  },
  {
    icon: <Cloud size={18} />,
    title: "Cloud",
    desc: "Docker, Kubernetes, CI/CD — skalowalność i niezawodność.",
    tech: ["Docker", "K8s", "CI/CD"],
  },
  {
    icon: <Smartphone size={18} />,
    title: "ERP/Integracje",
    desc: "Django, integracje API, moduły ERP i CRM.",
    tech: ["Django", "REST", "GraphQL"],
  },
];

export default function ServicesPage() {
  return (
    <Section>
      <h1 className="font-display text-4xl font-bold">Usługi</h1>
      <p className="mt-4 text-slate-300">Poniżej nasz przekrojowy zakres kompetencji technicznych i produktowych.</p>
      <div className="mt-8 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {services.map((s) => (
          <Card key={s.title} className="glass neon-hover" title={s.title}>
            <div className="mb-2 text-slate-200">{s.icon}</div>
            <p className="text-slate-300">{s.desc}</p>
            <div className="mt-3 flex flex-wrap gap-2">
              {s.tech.map((t) => (
                <span key={t} className="rounded-md border border-white/10 bg-white/5 px-2 py-1 text-xs text-slate-300">
                  {t}
                </span>
              ))}
            </div>
          </Card>
        ))}
      </div>
    </Section>
  );
}
