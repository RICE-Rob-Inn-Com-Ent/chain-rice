"use client";

import React from "react";
import Link from "next/link";
import { Icon } from "@iconify/react";
import { ModulesNav } from "@/components/ModulesNav";
import { InfraStatusGrid } from "@/components/InfraStatusGrid";

const features = [
  {
    icon: "mdi:brain",
    title: "Custom Model Training",
    description: "Fine-tune LLM-y LoRA, trenowanie od zera, profile inference'owe dla zespołów produktowych.",
    gradient: "from-purple-500/20 to-pink-500/20",
  },
  {
    icon: "mdi:gpu",
    title: "Decentralizowana sieć GPU",
    description: "Wymiana mocy obliczeniowej, klastry bare-metal i automatyczny scheduling jobów.",
    gradient: "from-cyan-500/20 to-blue-500/20",
  },
  {
    icon: "mdi:database",
    title: "Zarządzanie datasetami",
    description: "Mongo + Postgres + Lakehouse. Wersjonowanie zestawów i polityki retencji.",
    gradient: "from-emerald-500/20 to-teal-500/20",
  },
  {
    icon: "mdi:chart-line",
    title: "Real-time Benchmarking",
    description: "Prometheus + Grafana + Jaeger. Każdy eksperyment ma własny ślad i dashboard.",
    gradient: "from-amber-500/20 to-orange-500/20",
  },
  {
    icon: "mdi:code-tags",
    title: "Biblioteka Genów",
    description: "Parametry LoRA, schedulerów, optimizerów i presetów dla modeli enterprise.",
    gradient: "from-violet-500/20 to-purple-500/20",
  },
  {
    icon: "mdi:package-variant",
    title: "Marketplace modeli",
    description: "Publikowanie i sprzedaż modeli, modułów inference i kontenerów KServe.",
    gradient: "from-rose-500/20 to-pink-500/20",
  },
];

const models = [
  { name: "Phi-3", type: "LLM", vram: "6GB", color: "from-blue-500/20 to-cyan-500/20" },
  { name: "Llama 3.1", type: "LLM", vram: "13GB", color: "from-purple-500/20 to-pink-500/20" },
  { name: "Stable Diffusion XL", type: "Image Gen", vram: "10GB", color: "from-emerald-500/20 to-teal-500/20" },
  { name: "CodeGen", type: "Code", vram: "7GB", color: "from-amber-500/20 to-orange-500/20" },
  { name: "Whisper v3 turbo", type: "Audio", vram: "4GB", color: "from-violet-500/20 to-purple-500/20" },
  { name: "CLIP", type: "Vision", vram: "5GB", color: "from-rose-500/20 to-pink-500/20" },
  { name: "Embeddings", type: "Embedding", vram: "2GB", color: "from-indigo-500/20 to-blue-500/20" },
  { name: "Custom", type: "Module", vram: "Varies", color: "from-slate-500/20 to-gray-500/20" },
];

const Main = () => {
  return (
    <div className="min-h-screen bg-void-950 text-white">
      {/* Animated background grid */}
      <div className="fixed inset-0 -z-10 bg-[linear-gradient(to_right,#1f2047_1px,transparent_1px),linear-gradient(to_bottom,#1f2047_1px,transparent_1px)] bg-[size:4rem_4rem] opacity-20" />
      <div className="fixed inset-0 -z-10 bg-gradient-to-b from-void-950 via-void-900/50 to-void-950" />

      {/* Modern Navigation */}
      <nav className="sticky top-0 z-50 border-b border-white/5 bg-void-950/60 backdrop-blur-xl">
        <div className="container mx-auto flex items-center justify-between px-6 py-4">
          <Link href="/" className="group flex items-center gap-3 transition-transform hover:scale-105">
            <div className="relative">
              <span className="relative z-10 text-3xl font-display tracking-[0.4em] text-ion-400 transition-all group-hover:text-ion-300">
                RICE
              </span>
              <span className="absolute inset-0 text-3xl font-display tracking-[0.4em] text-ion-500/30 blur-sm">
                RICE
              </span>
            </div>
          </Link>
          <div className="flex flex-wrap items-center gap-4 text-sm">
            <Link href="/" className="font-semibold text-white transition-colors hover:text-ion-300">
              Home
            </Link>
            <ModulesNav />
          </div>
        </div>
      </nav>

      {/* Hero Section */}
      <section className="relative overflow-hidden border-b border-white/5">
        {/* Animated gradient orbs */}
        <div className="absolute -left-40 -top-40 h-96 w-96 rounded-full bg-ion-500/20 blur-3xl animate-pulse" />
        <div className="absolute -right-40 top-40 h-96 w-96 rounded-full bg-purple-500/20 blur-3xl animate-pulse" style={{ animationDelay: "1s" }} />
        
        <div className="relative container mx-auto grid gap-12 px-6 py-24 lg:grid-cols-[1.1fr_0.9fr] lg:py-32">
          <div className="space-y-8 animate-fade-in">
            <span className="inline-flex items-center gap-2 rounded-full border border-ion-400/30 bg-gradient-to-r from-ion-500/10 to-purple-500/10 px-5 py-2 text-xs font-semibold uppercase tracking-[0.5em] text-ion-300 backdrop-blur-sm">
              <span className="relative flex h-2 w-2">
                <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-ion-400 opacity-75"></span>
                <span className="relative inline-flex h-2 w-2 rounded-full bg-ion-400"></span>
              </span>
              AI Ops / Infra / GPU
            </span>
            <h1 className="text-5xl font-display leading-tight text-white md:text-7xl lg:text-8xl">
              <span className="bg-gradient-to-r from-white via-ion-200 to-white bg-clip-text text-transparent">
                Platforma treningowa,
              </span>
              <br />
              <span className="bg-gradient-to-r from-ion-400 via-purple-400 to-ion-400 bg-clip-text text-transparent">
                która zna każdy pakiet w repo.
              </span>
            </h1>
            <p className="text-xl leading-relaxed text-white/70 md:text-2xl">
              RICE spina moduły z lokalnych software house'ów w Rybniku: GPU sharing, blockchain rozliczeń, CRM modułów i
              real-time telemetry. Wszystko dark-mode, bez kompromisów.
            </p>
            <div className="flex flex-wrap gap-4">
              <Link
                href="/auth/signup"
                className="group relative overflow-hidden rounded-full bg-gradient-to-r from-ion-500 to-ion-600 px-8 py-4 text-sm font-semibold text-void-900 shadow-[0_0_40px_rgba(15,214,255,0.4)] transition-all duration-300 hover:scale-105 hover:shadow-[0_0_60px_rgba(15,214,255,0.6)]"
              >
                <span className="relative z-10">Uruchom sandbox</span>
                <div className="absolute inset-0 bg-gradient-to-r from-ion-400 to-ion-500 opacity-0 transition-opacity group-hover:opacity-100" />
              </Link>
              <Link
                href="/docs/install"
                className="group relative overflow-hidden rounded-full border-2 border-white/20 bg-void-900/50 px-8 py-4 text-sm font-semibold text-white/90 backdrop-blur-sm transition-all duration-300 hover:border-ion-400/50 hover:bg-void-900/70 hover:text-ion-200"
              >
                Czytaj dokumentację
                <Icon icon="mdi:arrow-right" className="ml-2 inline-block transition-transform group-hover:translate-x-1" />
              </Link>
            </div>
          </div>
          
          {/* Live Pipeline Card */}
          <div className="group relative animate-fade-in" style={{ animationDelay: "0.2s" }}>
            <div className="absolute -inset-0.5 rounded-[32px] bg-gradient-to-r from-ion-500/50 via-purple-500/50 to-ion-500/50 opacity-20 blur-xl transition-opacity group-hover:opacity-40" />
            <div className="relative rounded-[32px] border border-white/10 bg-gradient-to-br from-void-900/90 via-void-800/80 to-void-900/90 p-8 backdrop-blur-xl">
              <div className="mb-6 flex items-center gap-3">
                <div className="h-2 w-2 rounded-full bg-ion-400 animate-pulse" />
                <p className="text-xs font-semibold uppercase tracking-[0.4em] text-ion-300">Live pipeline</p>
              </div>
              <ul className="space-y-5 text-sm">
                {[
                  { label: "Prometheus scrape /api/metrics", value: "OK", status: "online" },
                  { label: "Jaeger traces dla LoRA", value: "42 aktywne", status: "online" },
                  { label: "Vault + Redis + Postgres", value: "ZRoutowane przez Traefik", status: "online" },
                  { label: "Grafana dashboards", value: "19 paneli", status: "online" },
                ].map((item, idx) => (
                  <li key={idx} className="flex items-center justify-between border-b border-white/5 pb-3 last:border-0">
                    <span className="text-white/80">{item.label}</span>
                    <span className="flex items-center gap-2 font-semibold text-ion-300">
                      {item.status === "online" && (
                        <span className="relative flex h-1.5 w-1.5">
                          <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-ion-400 opacity-75"></span>
                          <span className="relative inline-flex h-1.5 w-1.5 rounded-full bg-ion-400"></span>
                        </span>
                      )}
                      {item.value}
                    </span>
                  </li>
                ))}
              </ul>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="relative border-b border-white/5 bg-void-950 py-24">
        <div className="container mx-auto space-y-16 px-6">
          <header className="text-center space-y-4 animate-fade-in">
            <p className="text-xs font-semibold uppercase tracking-[0.4em] text-ion-400">Zakres funkcji</p>
            <h2 className="text-4xl font-display text-white md:text-5xl lg:text-6xl">
              <span className="bg-gradient-to-r from-white via-ion-200 to-white bg-clip-text text-transparent">
                Ciężki ciemny motyw.
              </span>
              <br />
              <span className="bg-gradient-to-r from-ion-400 to-purple-400 bg-clip-text text-transparent">
                Szybkie wdrożenia.
              </span>
            </h2>
          </header>
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {features.map((feature, idx) => (
              <article
                key={feature.title}
                className="group relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-void-900/80 to-void-800/60 p-8 backdrop-blur-sm transition-all duration-500 hover:scale-[1.02] hover:border-ion-400/30 hover:shadow-[0_0_40px_rgba(15,214,255,0.2)]"
                style={{ animationDelay: `${idx * 0.1}s` }}
              >
                <div className={`absolute inset-0 bg-gradient-to-br ${feature.gradient} opacity-0 transition-opacity duration-500 group-hover:opacity-100`} />
                <div className="relative z-10">
                  <div className="mb-6 inline-flex rounded-2xl bg-gradient-to-br from-void-800/50 to-void-900/50 p-4 backdrop-blur-sm">
                    <Icon icon={feature.icon} className="h-8 w-8 text-ion-300 transition-transform group-hover:scale-110" />
                  </div>
                  <h3 className="mb-3 text-2xl font-semibold text-white">{feature.title}</h3>
                  <p className="text-sm leading-relaxed text-white/70">{feature.description}</p>
                </div>
              </article>
            ))}
          </div>
        </div>
      </section>

      {/* Models Section */}
      <section className="relative border-b border-white/5 bg-void-950 py-24">
        <div className="container mx-auto space-y-12 px-6">
          <header className="text-center space-y-3">
            <h2 className="text-4xl font-display text-white md:text-5xl">
              <span className="bg-gradient-to-r from-white to-ion-200 bg-clip-text text-transparent">
                Modele produkcyjne
              </span>
            </h2>
            <p className="text-sm text-white/60">Konfiguracje, VRAM i typy inference.</p>
          </header>
          <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
            {models.map((model, idx) => (
              <div
                key={model.name}
                className="group relative overflow-hidden rounded-2xl border border-white/10 bg-gradient-to-br from-void-900/80 to-void-800/60 p-6 backdrop-blur-sm transition-all duration-300 hover:scale-105 hover:border-ion-400/30 hover:shadow-[0_0_30px_rgba(15,214,255,0.15)]"
                style={{ animationDelay: `${idx * 0.05}s` }}
              >
                <div className={`absolute inset-0 bg-gradient-to-br ${model.color} opacity-0 transition-opacity duration-300 group-hover:opacity-100`} />
                <div className="relative z-10">
                  <div className="mb-4 flex items-center justify-between">
                    <h4 className="font-semibold text-white">{model.name}</h4>
                    <span className="rounded-full bg-white/10 px-3 py-1 text-xs font-medium text-white/80 backdrop-blur-sm">
                      {model.type}
                    </span>
                  </div>
                  <p className="text-sm text-white/60">Min VRAM: <span className="font-semibold text-ion-300">{model.vram}</span></p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Infrastructure Status */}
      <section className="relative border-b border-white/5 bg-void-950 py-24">
        <div className="container mx-auto space-y-12 px-6">
          <header className="text-center space-y-3">
            <h2 className="text-4xl font-display text-white md:text-5xl">
              <span className="bg-gradient-to-r from-white to-ion-200 bg-clip-text text-transparent">
                Status infrastruktury
              </span>
            </h2>
            <p className="text-sm text-white/60">Real-time monitoring i telemetria</p>
          </header>
          <InfraStatusGrid />
        </div>
      </section>

      {/* CTA Section */}
      <section className="relative overflow-hidden bg-gradient-to-b from-void-900 via-void-950 to-void-950 py-24">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_center,_rgba(15,214,255,0.1),transparent_70%)]" />
        <div className="container relative mx-auto px-6 text-center space-y-8">
          <h2 className="text-4xl font-display text-white md:text-5xl lg:text-6xl">
            <span className="bg-gradient-to-r from-white via-ion-200 to-white bg-clip-text text-transparent">
              Toolchain bez wymówek
            </span>
          </h2>
          <p className="mx-auto max-w-3xl text-lg leading-relaxed text-white/70 md:text-xl">
            Sklonuj repo, skopiuj{" "}
            <code className="rounded-lg border border-white/10 bg-void-800/50 px-3 py-1.5 text-sm font-mono text-ion-300 backdrop-blur-sm">
              .env.example
            </code>
            , uruchom{" "}
            <code className="rounded-lg border border-white/10 bg-void-800/50 px-3 py-1.5 text-sm font-mono text-ion-300 backdrop-blur-sm">
              make install
            </code>
            . Redis, Mongo, Postgres, Vault i Traefik wstają automatycznie. Prometheus scrapuje /api/metrics, Jaeger zbiera OTLP.
          </p>
          <div className="flex flex-wrap justify-center gap-4">
            <Link
              href="/docs/install"
              className="group relative overflow-hidden rounded-full border-2 border-white/20 bg-void-900/50 px-8 py-4 text-sm font-semibold text-white/90 backdrop-blur-sm transition-all duration-300 hover:border-ion-400/50 hover:bg-void-900/70 hover:text-ion-200"
            >
              Instrukcje instalacji
              <Icon icon="mdi:arrow-right" className="ml-2 inline-block transition-transform group-hover:translate-x-1" />
            </Link>
            <Link
              href="/auth/signup"
              className="group relative overflow-hidden rounded-full bg-gradient-to-r from-white to-ion-100 px-8 py-4 text-sm font-semibold text-void-900 shadow-lg transition-all duration-300 hover:scale-105 hover:shadow-xl hover:shadow-ion-500/20"
            >
              <span className="relative z-10">Wejdź do sieci GPU</span>
              <div className="absolute inset-0 bg-gradient-to-r from-ion-200 to-white opacity-0 transition-opacity group-hover:opacity-100" />
            </Link>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Main;
