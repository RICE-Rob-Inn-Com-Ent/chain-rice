"use client";

import React, { useState } from "react";
import Link from "next/link";
import { Icon } from "@iconify/react";
import { COMPANY_MODULES, getCategories, type ModuleCategory } from "@/lib/company-modules";

// Mapowanie priorytetów z TODO_MODULES.md
const MODULE_PRIORITIES: Record<string, "HIGH" | "MEDIUM" | "LOW"> = {
  "alan-systems": "HIGH",
  "apject": "HIGH",
  "sharpai": "HIGH",
  "hostersi": "HIGH",
  "spiid": "HIGH",
  "biostat": "MEDIUM",
  "digitree": "MEDIUM",
  "firetms": "MEDIUM",
  "linkpoint": "MEDIUM",
  "medifile": "MEDIUM",
  "nomonday": "MEDIUM",
  "sixteractive": "MEDIUM",
  "fireup": "LOW",
  "serversms": "LOW",
};

const Modules: React.FC = () => {
  const [selectedCategory, setSelectedCategory] = useState<ModuleCategory | "ALL">("ALL");
  const [searchQuery, setSearchQuery] = useState("");
  const categories = getCategories();

  const filteredModules = COMPANY_MODULES.filter((module) => {
    const matchesCategory = selectedCategory === "ALL" || module.category === selectedCategory;
    const matchesSearch =
      searchQuery === "" ||
      module.name.toLowerCase().includes(searchQuery.toLowerCase()) ||
      module.description.toLowerCase().includes(searchQuery.toLowerCase()) ||
      module.inspiredBy.toLowerCase().includes(searchQuery.toLowerCase());
    return matchesCategory && matchesSearch;
  });

  const getPriorityBadge = (moduleId: string) => {
    const priority = MODULE_PRIORITIES[moduleId] || "MEDIUM";
    const config = {
      HIGH: { emoji: "🔴", label: "Wysoki", color: "from-red-600 to-red-700" },
      MEDIUM: { emoji: "🟡", label: "Średni", color: "from-yellow-600 to-yellow-700" },
      LOW: { emoji: "🟢", label: "Niski", color: "from-green-600 to-green-700" },
    };
    return config[priority];
  };

  return (
    <div className="min-h-screen bg-gradient-to-b from-black via-gray-900 to-black">
      {/* Navigation */}
      <nav className="border-b border-gray-800 bg-black/50 backdrop-blur-sm sticky top-0 z-50">
        <div className="container mx-auto px-6 py-4">
          <div className="flex items-center justify-between">
            <Link href="/" className="flex items-center gap-3">
              <div className="text-2xl font-bold font-orbitron bg-gradient-to-r from-blue-400 to-purple-400 bg-clip-text text-transparent">
                RICE
              </div>
            </Link>
            <div className="flex items-center gap-6">
              <Link href="/" className="text-gray-300 hover:text-white transition-colors">
                Home
              </Link>
              <Link href="/modules" className="text-blue-400 font-semibold">
                Moduły Firm
              </Link>
              <Link href="/about" className="text-gray-300 hover:text-white transition-colors">
                O nas
              </Link>
              <Link href="/contact" className="text-gray-300 hover:text-white transition-colors">
                Kontakt
              </Link>
            </div>
          </div>
        </div>
      </nav>
      {/* Hero Section */}
      <section className="relative overflow-hidden">
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-blue-900/20 via-transparent to-transparent"></div>
        <div className="container mx-auto px-6 py-20 relative z-10">
          <div className="max-w-5xl mx-auto text-center">
            <div className="flex items-center justify-center gap-4 mb-6">
              <Icon icon="mdi:office-building-cog" className="text-6xl text-blue-400" />
              <h1 className="text-5xl md:text-6xl font-bold font-orbitron bg-gradient-to-r from-blue-400 via-purple-400 to-pink-400 bg-clip-text text-transparent">
                Moduły Firm IT
              </h1>
            </div>
            <p className="text-xl md:text-2xl text-gray-300 mb-6 font-poppins">
              14 modułów inspirowanych lokalnymi firmami z Rybnika
            </p>
            <p className="text-lg text-gray-400 mb-8">
              System oparty na doświadczeniach realnych firm IT — od AI i cloud computing, przez DevOps,
              aż po logistykę i medycynę
            </p>
            <a
              href="https://rybnickie.it/firmy"
              target="_blank"
              rel="noopener noreferrer"
              className="inline-flex items-center gap-2 text-blue-400 hover:text-blue-300 transition-colors"
            >
              <Icon icon="mdi:link-variant" className="text-xl" />
              <span>rybnickie.it/firmy</span>
            </a>
          </div>
        </div>
      </section>

      {/* Stats Section */}
      <section className="py-12 bg-black/50">
        <div className="container mx-auto px-6">
          <div className="grid grid-cols-2 md:grid-cols-4 gap-6 max-w-4xl mx-auto">
            {[
              { icon: "mdi:cube-outline", value: "14", label: "Modułów" },
              { icon: "mdi:tag-multiple", value: "11", label: "Kategorii" },
              { icon: "mdi:robot", value: "5", label: "Modeli AI" },
              { icon: "mdi:office-building", value: "14", label: "Firm" },
            ].map((stat, idx) => (
              <div
                key={idx}
                className="bg-gradient-to-br from-gray-900 to-gray-800 p-6 rounded-xl border border-gray-700 text-center"
              >
                <Icon icon={stat.icon} className="text-4xl text-blue-400 mx-auto mb-2" />
                <div className="text-3xl font-bold font-orbitron mb-1">{stat.value}</div>
                <div className="text-sm text-gray-400">{stat.label}</div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Search and Filter */}
      <section className="py-8 bg-black/30">
        <div className="container mx-auto px-6">
          <div className="max-w-4xl mx-auto">
            <div className="grid md:grid-cols-[1fr_300px] gap-4">
              {/* Search */}
              <div className="relative">
                <Icon
                  icon="mdi:magnify"
                  className="absolute left-4 top-1/2 -translate-y-1/2 text-2xl text-gray-400"
                />
                <input
                  type="text"
                  placeholder="Szukaj modułów, firm, funkcjonalności..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full bg-gray-900 border border-gray-700 rounded-lg pl-12 pr-4 py-4 text-white placeholder:text-gray-500 focus:outline-none focus:border-blue-500 transition-colors"
                />
              </div>

              {/* Category Filter */}
              <select
                value={selectedCategory}
                onChange={(e) => setSelectedCategory(e.target.value as ModuleCategory | "ALL")}
                className="bg-gray-900 border border-gray-700 rounded-lg px-4 py-4 text-white focus:outline-none focus:border-blue-500 appearance-none cursor-pointer"
              >
                <option value="ALL">Wszystkie kategorie</option>
                {categories.map((cat) => (
                  <option key={cat} value={cat}>
                    {cat}
                  </option>
                ))}
              </select>
            </div>

            {/* Results count */}
            <div className="mt-4 text-center text-gray-400">
              Wyświetlono: <span className="text-white font-semibold">{filteredModules.length}</span> /{" "}
              {COMPANY_MODULES.length}
            </div>
          </div>
        </div>
      </section>

      {/* Modules Grid */}
      <section className="py-16">
        <div className="container mx-auto px-6">
          <div className="grid md:grid-cols-2 lg:grid-cols-3 gap-8 max-w-7xl mx-auto">
            {filteredModules.map((module) => {
              const priority = getPriorityBadge(module.id);
              return (
                <div
                  key={module.id}
                  className="bg-gradient-to-br from-gray-900 to-gray-800 rounded-xl border border-gray-700 hover:border-blue-500 transition-all group overflow-hidden"
                >
                  {/* Header with Icon and Priority */}
                  <div className="p-6 border-b border-gray-700">
                    <div className="flex items-start justify-between mb-4">
                      <div
                        className="p-4 rounded-lg"
                        style={{ backgroundColor: module.color + "20" }}
                      >
                        <Icon
                          icon={module.icon || "mdi:cube-outline"}
                          className="text-4xl"
                          style={{ color: module.color }}
                        />
                      </div>
                      <div
                        className={`px-3 py-1 rounded-full text-xs font-semibold bg-gradient-to-r ${priority.color} flex items-center gap-1`}
                      >
                        <span>{priority.emoji}</span>
                        <span>{priority.label}</span>
                      </div>
                    </div>

                    <h3 className="text-2xl font-bold mb-2 font-orbitron group-hover:text-blue-400 transition-colors">
                      {module.name}
                    </h3>
                    <p className="text-sm text-gray-400 font-poppins">{module.category}</p>
                  </div>

                  {/* Content */}
                  <div className="p-6">
                    <p className="text-gray-300 text-sm mb-4 leading-relaxed line-clamp-3">
                      {module.description}
                    </p>

                    {/* Features */}
                    <div className="space-y-2 mb-6">
                      {module.features.slice(0, 4).map((feature, idx) => (
                        <div key={idx} className="flex items-start gap-2 text-sm">
                          <Icon
                            icon="mdi:check-circle"
                            className="text-green-500 flex-shrink-0 mt-0.5"
                          />
                          <span className="text-gray-400 line-clamp-1">{feature}</span>
                        </div>
                      ))}
                      {module.features.length > 4 && (
                        <p className="text-xs text-gray-500 ml-6">
                          +{module.features.length - 4} więcej funkcji
                        </p>
                      )}
                    </div>

                    {/* AI Models */}
                    {module.aiCapabilities.models && (
                      <div className="mb-4">
                        <p className="text-xs text-gray-500 mb-2">Modele AI:</p>
                        <div className="flex flex-wrap gap-2">
                          {module.aiCapabilities.models.slice(0, 3).map((model, idx) => (
                            <span
                              key={idx}
                              className="px-2 py-1 bg-purple-900/30 border border-purple-700 rounded text-xs text-purple-300"
                            >
                              {model}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}

                    {/* Footer */}
                    <div className="pt-4 border-t border-gray-700">
                      <div className="flex items-center justify-between">
                        <div className="flex items-center gap-2 text-xs text-gray-500">
                          <Icon icon="mdi:lightbulb-on-outline" className="text-sm" />
                          <span className="line-clamp-1">{module.inspiredBy.split('-')[0]}</span>
                        </div>
                        <Icon
                          icon="mdi:arrow-right-circle"
                          className="text-2xl text-blue-500 group-hover:translate-x-1 transition-transform"
                        />
                      </div>
                    </div>
                  </div>
                </div>
              );
            })}
          </div>

          {/* No Results */}
          {filteredModules.length === 0 && (
            <div className="text-center py-20">
              <Icon icon="mdi:cloud-search-outline" className="text-6xl text-gray-600 mx-auto mb-4" />
              <h3 className="text-2xl font-semibold text-gray-400 mb-2 font-orbitron">Brak wyników</h3>
              <p className="text-gray-500">Spróbuj zmienić kryteria wyszukiwania</p>
            </div>
          )}
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20 bg-gradient-to-b from-black to-gray-900">
        <div className="container mx-auto px-6">
          <div className="max-w-4xl mx-auto text-center">
            <h2 className="text-4xl font-bold font-orbitron mb-6">
              Zainteresowany integracją modułów?
            </h2>
            <p className="text-xl text-gray-300 mb-8 font-poppins">
              Skontaktuj się z nami, aby dowiedzieć się więcej o możliwościach implementacji
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link
                href="/contact"
                className="px-8 py-4 bg-gradient-to-r from-blue-600 to-purple-600 rounded-lg font-semibold hover:from-blue-700 hover:to-purple-700 transition-all transform hover:scale-105"
              >
                Kontakt
              </Link>
              <Link
                href="/about"
                className="px-8 py-4 bg-white/10 backdrop-blur-sm border border-white/20 rounded-lg font-semibold hover:bg-white/20 transition-all"
              >
                O nas
              </Link>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
};

export default Modules;

