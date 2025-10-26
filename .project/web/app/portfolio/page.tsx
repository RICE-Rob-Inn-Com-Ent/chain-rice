import React from "react";
import Section from "@atoms/Section";
import Link from "next/link";

type Project = {
  slug: string;
  name: string;
  summary: string;
  tags: string[];
  gradient: string;
  icon: string;
};

const projects: Project[] = [
  {
    slug: "ceramix",
    name: "CeramiX",
    summary: "Platforma e-commerce z AI image generation dla indyjskiego rynku ceramiki artystycznej.",
    tags: ["Next.js", "AI", "Stable Diffusion", "India"],
    gradient: "from-orange-500/20 to-red-500/20",
    icon: "🏺",
  },
  {
    slug: "superborowki",
    name: "Superborówki",
    summary: "Aplikacja mobilna Flutter do zarządzania plantacją borówek dla rynku japońskiego.",
    tags: ["Flutter", "IoT", "Firebase", "Japan"],
    gradient: "from-blue-500/20 to-purple-500/20",
    icon: "🫐",
  },
  {
    slug: "pantheon-ai",
    name: "Panteon Egipskich Bogów AI",
    summary: "6 specjalistycznych modeli AI (Thoth, Ra, Isis, Bastet, Maat, Khnum) z LoRA fine-tuning.",
    tags: ["Docker", "Ollama", "FastAPI", "Next.js"],
    gradient: "from-amber-500/20 to-yellow-500/20",
    icon: "⚱️",
  },
  {
    slug: "backend-microservices",
    name: "Backend Microservices",
    summary: "Architektura mikroserwisów w Go z CQRS, DDD, GraphQL i gRPC.",
    tags: ["Go", "CQRS", "GraphQL", "gRPC"],
    gradient: "from-cyan-500/20 to-blue-500/20",
    icon: "🔧",
  },
  {
    slug: "schema-system",
    name: "Proto Schema System",
    summary: "600+ definicji Protocol Buffers dla komunikacji międzyserwisowej.",
    tags: ["Protobuf", "gRPC", "Bazel"],
    gradient: "from-green-500/20 to-emerald-500/20",
    icon: "📋",
  },
  {
    slug: "devops-infra",
    name: "DevOps Infrastructure",
    summary: "Kubernetes, Terraform, Ansible - pełna automatyzacja deploymentu i skalowania.",
    tags: ["K8s", "Terraform", "Ansible", "CI/CD"],
    gradient: "from-purple-500/20 to-pink-500/20",
    icon: "☁️",
  },
];

export const metadata = { title: "Portfolio — RICE" };

export default function PortfolioPage() {
  return (
    <Section>
      <h1 className="font-display text-4xl font-bold">Portfolio</h1>
      <p className="mt-4 text-slate-300">Wybrane realizacje i koncepcje. Kliknij, aby poznać szczegóły.</p>
      <div className="mt-8 grid gap-6 md:grid-cols-2 lg:grid-cols-3">
        {projects.map((p) => (
          <Link
            key={p.slug}
            href={`/portfolio/${p.slug}`}
            className="group rounded-lg border border-white/10 bg-white/5 p-6 transition hover:border-cyan-400/40 hover:shadow-[0_0_25px_rgba(34,211,238,0.25)] hover:scale-[1.02]"
          >
            <div
              className={`h-32 w-full rounded-md bg-gradient-to-br ${p.gradient} flex items-center justify-center text-6xl group-hover:scale-110 transition-transform`}
            >
              {p.icon}
            </div>
            <h3 className="mt-4 text-xl font-semibold text-slate-100">{p.name}</h3>
            <p className="mt-2 text-sm text-slate-300 leading-relaxed">{p.summary}</p>
            <div className="mt-4 flex flex-wrap gap-2">
              {p.tags.map((tag) => (
                <span key={tag} className="text-xs bg-white/10 text-slate-400 px-2 py-1 rounded">
                  {tag}
                </span>
              ))}
            </div>
          </Link>
        ))}
      </div>
    </Section>
  );
}
