"use client";

import { Card } from "../base/Card";
import { Button } from "../base/Button";
import GradientText from "../base/GradientText";
import Reveal from "../base/Reveal";

export default function LoRaTrainingPanel() {
  return (
    <section id="lora" className="py-20 px-4 bg-gradient-to-b from-black to-purple-900/20">
      <div className="max-w-7xl mx-auto">
        <Reveal>
          <h2 className="text-4xl font-bold text-center mb-4">
            <GradientText>LoRA Training</GradientText>
          </h2>
          <p className="text-center text-gray-400 mb-12">Trenuj własne adaptery bez kosztownego fine-tuningu</p>
        </Reveal>

        <div className="grid md:grid-cols-2 gap-8">
          <Reveal delay={0.1}>
            <Card className="bg-gradient-to-br from-purple-900/30 to-black border border-purple-500/30 p-8">
              <h3 className="text-2xl font-bold mb-4 text-purple-400">Co to jest LoRA?</h3>
              <p className="text-gray-400 mb-4">
                Low-Rank Adaptation pozwala dostosować modele AI do konkretnych zadań bez pełnego trenowania. Zamiast
                modyfikować wszystkie wagi modelu, LoRA dodaje małe "adaptery" które można szybko trenować.
              </p>
              <ul className="space-y-2 text-gray-300">
                <li>✓ Trenowanie w minuty zamiast dni</li>
                <li>✓ Wymaga ~1GB VRAM zamiast ~80GB</li>
                <li>✓ Łatwe przełączanie między adapterami</li>
                <li>✓ Możliwość łączenia wielu adapterów</li>
              </ul>
            </Card>
          </Reveal>

          <Reveal delay={0.2}>
            <Card className="bg-gradient-to-br from-purple-900/30 to-black border border-purple-500/30 p-8">
              <h3 className="text-2xl font-bold mb-4 text-purple-400">Przykłady Zastosowań</h3>
              <div className="space-y-4">
                <div>
                  <h4 className="font-semibold text-white mb-1">🏢 Firmowy Asystent</h4>
                  <p className="text-gray-400 text-sm">Naucz model używać firmowego języka, procedur i dokumentacji</p>
                </div>
                <div>
                  <h4 className="font-semibold text-white mb-1">🎨 Styl Graficzny</h4>
                  <p className="text-gray-400 text-sm">
                    Trenuj model generowania obrazów w konkretnym stylu artystycznym
                  </p>
                </div>
                <div>
                  <h4 className="font-semibold text-white mb-1">📝 Specjalistyczne Treści</h4>
                  <p className="text-gray-400 text-sm">
                    Generuj treści medyczne, prawne lub techniczne z wysoką precyzją
                  </p>
                </div>

                <Button className="w-full mt-4 bg-gradient-to-r from-purple-600 to-pink-600 hover:from-purple-700 hover:to-pink-700">
                  Rozpocznij Training →
                </Button>
              </div>
            </Card>
          </Reveal>
        </div>
      </div>
    </section>
  );
}
