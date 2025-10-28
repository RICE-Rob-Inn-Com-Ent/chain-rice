"use client";

import React, { useState } from "react";
import { Card } from "../base/Card";
import { Button } from "../base/Button";

/**
 * PricingCalculator - Interactive pricing calculator
 */
export const PricingCalculator: React.FC = () => {
  const [hours, setHours] = useState(40);
  const [developers, setDevelopers] = useState(1);
  const hourlyRate = 350; // PLN/h

  const total = hours * developers * hourlyRate;

  return (
    <Card className="bg-gradient-to-br from-green-900/20 to-gray-900 p-8">
      <h3 className="mb-6 text-2xl font-bold text-green-400">Kalkulator Kosztów</h3>

      <div className="space-y-6">
        <div>
          <label className="mb-2 block text-sm font-medium text-gray-300">
            Liczba godzin: <span className="text-green-400">{hours}h</span>
          </label>
          <input
            type="range"
            min="10"
            max="200"
            value={hours}
            onChange={(e) => setHours(Number(e.target.value))}
            className="w-full"
          />
        </div>

        <div>
          <label className="mb-2 block text-sm font-medium text-gray-300">
            Liczba developerów: <span className="text-green-400">{developers}</span>
          </label>
          <input
            type="range"
            min="1"
            max="5"
            value={developers}
            onChange={(e) => setDevelopers(Number(e.target.value))}
            className="w-full"
          />
        </div>

        <div className="mt-8 rounded-lg border border-green-500/30 bg-green-900/20 p-6 text-center">
          <div className="text-sm text-gray-400">Szacowany koszt:</div>
          <div className="mt-2 text-4xl font-bold text-green-400">{total.toLocaleString("pl-PL")} PLN</div>
          <div className="mt-1 text-xs text-gray-500">
            ({hours}h × {developers} dev × {hourlyRate} PLN/h)
          </div>
        </div>

        <Button className="w-full">Zapytaj o wycenę</Button>
      </div>
    </Card>
  );
};

export default PricingCalculator;
