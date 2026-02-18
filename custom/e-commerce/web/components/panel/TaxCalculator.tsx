"use client";

import { Calculator, FileText, Download } from "lucide-react";
import { useState } from "react";

interface TaxCalculatorProps {
  taxData: {
    yearlyRevenue: number;
    yearlyDonations: number;
    orders: any[];
  };
}

// Algorytmy podatkowe zgodne z prawem polskim dla fundacji
const TAX_RATES = {
  VAT: 0.23, // 23% VAT standardowy
  VAT_REDUCED: 0.08, // 8% VAT obniżony (żywność)
  VAT_ZERO: 0.0, // 0% VAT (darowizny na cele pożytku publicznego)
  CIT: 0.0, // Fundacje zwolnione z CIT
  PIT: 0.0, // Darowizny zwolnione z PIT
};

export default function TaxCalculator({ taxData }: TaxCalculatorProps) {
  const [selectedYear, setSelectedYear] = useState(new Date().getFullYear());

  // Kalkulacja VAT
  const calculateVAT = () => {
    // Fundacje zwolnione z VAT na darowizny
    // Ale płacą VAT na sprzedaż produktów
    const revenueVAT = taxData.yearlyRevenue * TAX_RATES.VAT;
    const donationsVAT = 0; // Zwolnione
    return {
      revenueVAT,
      donationsVAT,
      totalVAT: revenueVAT,
    };
  };

  // Kalkulacja podatku dochodowego
  const calculateIncomeTax = () => {
    // Fundacje zwolnione z CIT
    // Ale muszą płacić podatek od działalności gospodarczej
    const taxableIncome = taxData.yearlyRevenue - taxData.yearlyDonations;
    // Fundacje mogą odliczyć darowizny
    return {
      taxableIncome,
      tax: 0, // Fundacje zwolnione z CIT
      donationsDeductible: taxData.yearlyDonations,
    };
  };

  const vat = calculateVAT();
  const incomeTax = calculateIncomeTax();

  return (
    <div className="space-y-6">
      {/* Tax Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-white rounded-xl p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <Calculator className="w-8 h-8 text-meo-primary" />
            <FileText className="w-5 h-5 text-meo-brown-600" />
          </div>
          <p className="text-sm text-meo-brown-600">VAT do zapłaty</p>
          <p className="text-2xl font-bold text-meo-brown-800 mt-2">
            {vat.totalVAT.toLocaleString("pl-PL", {
              minimumFractionDigits: 2,
              maximumFractionDigits: 2,
            })}{" "}
            zł
          </p>
          <p className="text-xs text-meo-brown-600 mt-1">
            Darowizny zwolnione z VAT
          </p>
        </div>

        <div className="bg-white rounded-xl p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <Calculator className="w-8 h-8 text-meo-accent" />
            <FileText className="w-5 h-5 text-meo-brown-600" />
          </div>
          <p className="text-sm text-meo-brown-600">CIT (zwolnione)</p>
          <p className="text-2xl font-bold text-meo-brown-800 mt-2">
            {incomeTax.tax.toLocaleString("pl-PL", {
              minimumFractionDigits: 2,
              maximumFractionDigits: 2,
            })}{" "}
            zł
          </p>
          <p className="text-xs text-meo-brown-600 mt-1">
            Fundacje zwolnione z CIT
          </p>
        </div>

        <div className="bg-white rounded-xl p-6 shadow-soft">
          <div className="flex items-center justify-between mb-4">
            <Calculator className="w-8 h-8 text-meo-nature" />
            <FileText className="w-5 h-5 text-meo-brown-600" />
          </div>
          <p className="text-sm text-meo-brown-600">Odliczenia</p>
          <p className="text-2xl font-bold text-meo-brown-800 mt-2">
            {incomeTax.donationsDeductible.toLocaleString("pl-PL", {
              minimumFractionDigits: 2,
              maximumFractionDigits: 2,
            })}{" "}
            zł
          </p>
          <p className="text-xs text-meo-brown-600 mt-1">
            Darowizny odliczane od dochodu
          </p>
        </div>
      </div>

      {/* Detailed Breakdown */}
      <div className="bg-white rounded-2xl p-6 shadow-soft">
        <h2 className="text-xl font-bold text-meo-brown-800 mb-4">
          Szczegółowa kalkulacja podatkowa
        </h2>
        <div className="space-y-4">
          <div className="grid grid-cols-2 gap-4">
            <div>
              <p className="text-sm text-meo-brown-600">Przychód roczny</p>
              <p className="text-lg font-semibold text-meo-brown-800">
                {taxData.yearlyRevenue.toLocaleString("pl-PL")} zł
              </p>
            </div>
            <div>
              <p className="text-sm text-meo-brown-600">Darowizny roczne</p>
              <p className="text-lg font-semibold text-meo-brown-800">
                {taxData.yearlyDonations.toLocaleString("pl-PL")} zł
              </p>
            </div>
          </div>
          <div className="border-t border-meo-beige-200 pt-4">
            <div className="space-y-2">
              <div className="flex justify-between">
                <span className="text-meo-brown-700">VAT od sprzedaży (23%)</span>
                <span className="font-semibold text-meo-brown-800">
                  {vat.revenueVAT.toLocaleString("pl-PL", {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2,
                  })}{" "}
                  zł
                </span>
              </div>
              <div className="flex justify-between">
                <span className="text-meo-brown-700">VAT od darowizn (zwolnione)</span>
                <span className="font-semibold text-green-600">0.00 zł</span>
              </div>
              <div className="flex justify-between pt-2 border-t border-meo-beige-200">
                <span className="font-semibold text-meo-brown-800">
                  VAT do zapłaty
                </span>
                <span className="font-bold text-meo-brown-800">
                  {vat.totalVAT.toLocaleString("pl-PL", {
                    minimumFractionDigits: 2,
                    maximumFractionDigits: 2,
                  })}{" "}
                  zł
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Export Button */}
      <div className="flex justify-end">
        <button className="bg-meo-primary text-white px-6 py-3 rounded-xl font-semibold hover:bg-meo-brown-700 transition-colors flex items-center gap-2">
          <Download className="w-5 h-5" />
          Eksportuj raport podatkowy
        </button>
      </div>
    </div>
  );
}










