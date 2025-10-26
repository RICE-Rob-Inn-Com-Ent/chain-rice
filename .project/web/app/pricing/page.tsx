import React from "react";
import Section from "../../components/Section";
import { Button } from "@web/components/ui/Button";
import PricingCalculator from "../../components/PricingCalculator";

export const metadata = { title: "Cennik — RICE" };

export default function PricingPage() {
  return (
    <>
      <Section>
        <div className="mx-auto max-w-3xl text-center">
          <h1 className="text-4xl font-bold gradient-text">Cennik</h1>
          <p className="mt-3 text-slate-300">Przejrzyste pakiety oraz szybki kalkulator szacunkowy.</p>
        </div>
        <div className="mt-10 grid gap-6 md:grid-cols-3">
          <div className="rounded-xl border border-white/10 bg-white/5 p-6">
            <div className="text-sm text-slate-400">Start</div>
            <div className="mt-2 text-3xl font-semibold">4 900 PLN</div>
            <ul className="mt-4 space-y-2 text-sm text-slate-300">
              <li>Do 5 podstron</li>
              <li>Formularz kontaktowy</li>
              <li>Hosting i wdrożenie</li>
            </ul>
            <div className="mt-5">
              <Button variant="outline" size="sm">
                Wybierz
              </Button>
            </div>
          </div>
          <div className="rounded-xl border border-white/10 bg-white/5 p-6">
            <div className="text-sm text-slate-400">Pro</div>
            <div className="mt-2 text-3xl font-semibold">9 900 PLN</div>
            <ul className="mt-4 space-y-2 text-sm text-slate-300">
              <li>SSR/SEO, CMS</li>
              <li>Integracje (2)</li>
              <li>Analityka i monitoring</li>
            </ul>
            <div className="mt-5">
              <Button variant="outline" size="sm">
                Wybierz
              </Button>
            </div>
          </div>
          <div className="rounded-xl border border-white/10 bg-white/5 p-6">
            <div className="text-sm text-slate-400">Enterprise</div>
            <div className="mt-2 text-3xl font-semibold">Indywidualnie</div>
            <ul className="mt-4 space-y-2 text-sm text-slate-300">
              <li>Architektura i automatyzacja</li>
              <li>Integracje AI</li>
              <li>Wsparcie SLA</li>
            </ul>
            <div className="mt-5">
              <a href="#contact">
                <Button variant="outline" size="sm">
                  Porozmawiajmy
                </Button>
              </a>
            </div>
          </div>
        </div>

        <div className="mt-12">
          <PricingCalculator />
        </div>
      </Section>

      {/* AI Packages Section */}
      <Section id="ai-packages">
        <div className="mx-auto max-w-3xl text-center mb-10">
          <h2 className="text-4xl font-bold gradient-text">Pakiety AI Models</h2>
          <p className="mt-3 text-slate-300">Hosting i zarządzanie modelami AI - od małych po enterprise</p>
        </div>

        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-4">
          {/* Simple Package */}
          <div className="rounded-xl border border-cyan-500/30 bg-gradient-to-br from-cyan-900/20 to-gray-900 p-6">
            <div className="text-sm text-cyan-400 font-semibold">Simple</div>
            <div className="mt-2 text-3xl font-bold">
              499 PLN<span className="text-base text-gray-400">/mies</span>
            </div>
            <div className="mt-1 text-xs text-gray-500">7B models</div>
            <ul className="mt-4 space-y-2 text-sm text-slate-300">
              <li>✓ Mistral 7B Q4</li>
              <li>✓ Llama 3.2 7B</li>
              <li>✓ CodeLlama 7B</li>
              <li>✓ 4-5GB VRAM</li>
              <li>✓ API access</li>
            </ul>
            <div className="mt-5">
              <Button variant="outline" size="sm">
                Wybierz
              </Button>
            </div>
          </div>

          {/* Basic Package */}
          <div className="rounded-xl border border-blue-500/30 bg-gradient-to-br from-blue-900/20 to-gray-900 p-6">
            <div className="text-sm text-blue-400 font-semibold">Basic</div>
            <div className="mt-2 text-3xl font-bold">
              899 PLN<span className="text-base text-gray-400">/mies</span>
            </div>
            <div className="mt-1 text-xs text-gray-500">13B models</div>
            <ul className="mt-4 space-y-2 text-sm text-slate-300">
              <li>✓ Mistral 13B</li>
              <li>✓ Llama 3.1 13B</li>
              <li>✓ Vicuna 13B</li>
              <li>✓ 7-8GB VRAM</li>
              <li>✓ API + Dashboard</li>
            </ul>
            <div className="mt-5">
              <Button variant="outline" size="sm">
                Wybierz
              </Button>
            </div>
          </div>

          {/* Pro Package */}
          <div className="rounded-xl border border-purple-500/30 bg-gradient-to-br from-purple-900/20 to-gray-900 p-6">
            <div className="text-sm text-purple-400 font-semibold">Pro</div>
            <div className="mt-2 text-3xl font-bold">
              2499 PLN<span className="text-base text-gray-400">/mies</span>
            </div>
            <div className="mt-1 text-xs text-gray-500">70B models</div>
            <ul className="mt-4 space-y-2 text-sm text-slate-300">
              <li>✓ Llama 3.3 70B</li>
              <li>✓ Mixtral 8x7B</li>
              <li>✓ Qwen 2.5 72B</li>
              <li>✓ 40GB+ VRAM</li>
              <li>✓ Dedicated GPU</li>
            </ul>
            <div className="mt-5">
              <Button variant="outline" size="sm">
                Wybierz
              </Button>
            </div>
          </div>

          {/* Commercial APIs */}
          <div className="rounded-xl border border-amber-500/30 bg-gradient-to-br from-amber-900/20 to-gray-900 p-6">
            <div className="text-sm text-amber-400 font-semibold">Commercial</div>
            <div className="mt-2 text-3xl font-bold">Pay-as-go</div>
            <div className="mt-1 text-xs text-gray-500">API only</div>
            <ul className="mt-4 space-y-2 text-sm text-slate-300">
              <li>✓ OpenAI GPT-4</li>
              <li>✓ Claude 3.5</li>
              <li>✓ Gemini Pro</li>
              <li>✓ Cursor AI</li>
              <li>✓ od 0.01 PLN/1k tok</li>
            </ul>
            <div className="mt-5">
              <Button variant="outline" size="sm">
                Wybierz
              </Button>
            </div>
          </div>
        </div>

        <div className="mt-8 text-center text-sm text-gray-500">
          💡 Wszystkie pakiety zawierają: LoRA fine-tuning, monitoring, backup, wsparcie techniczne
        </div>
      </Section>
    </>
  );
}
