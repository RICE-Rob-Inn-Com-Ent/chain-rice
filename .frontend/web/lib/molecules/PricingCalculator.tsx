"use client";
import React, { useMemo, useState } from "react";
import { Button } from "../atoms/Button";

export default function PricingCalculator() {
  const [features, setFeatures] = useState(6);
  const [integrations, setIntegrations] = useState(2);
  const [ai, setAi] = useState(false);

  const estimate = useMemo(() => {
    const base = 4000;
    const featureCost = features * 500;
    const integrationsCost = integrations * 800;
    const aiCost = ai ? 3000 : 0;
    return base + featureCost + integrationsCost + aiCost;
  }, [features, integrations, ai]);

  return (
    <div className="rounded-xl border border-white/10 bg-white/5 p-5">
      <div className="grid gap-4 md:grid-cols-3">
        <div>
          <label className="mb-1 block text-sm text-slate-300">Funkcjonalności: {features}</label>
          <input
            type="range"
            min={1}
            max={20}
            value={features}
            onChange={(e: any) => setFeatures(Number(e.target.value))}
            className="w-full"
          />
        </div>
        <div>
          <label className="mb-1 block text-sm text-slate-300">Integracje: {integrations}</label>
          <input
            type="range"
            min={0}
            max={10}
            value={integrations}
            onChange={(e: any) => setIntegrations(Number(e.target.value))}
            className="w-full"
          />
        </div>
        <div className="flex items-end gap-2">
          <input id="ai" type="checkbox" checked={ai} onChange={(e: any) => setAi(e.target.checked)} />
          <label htmlFor="ai" className="text-sm text-slate-300">
            Moduł AI
          </label>
        </div>
      </div>
      <div className="mt-4 flex items-center justify-between">
        <div className="text-slate-300">Szacunkowy koszt</div>
        <div className="text-2xl font-semibold gradient-text">~ {estimate.toLocaleString("pl-PL")} PLN</div>
      </div>
      <div className="mt-3 text-right">
        <a href="#contact">
          <Button variant="outline" size="sm">
            Zapytaj o wycenę
          </Button>
        </a>
      </div>
    </div>
  );
}
