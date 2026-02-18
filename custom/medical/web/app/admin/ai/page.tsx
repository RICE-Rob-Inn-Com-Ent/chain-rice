"use client";

import { useState, useEffect } from "react";
import CerAI from "@/app/components/CerAI";

type ServiceStatus = {
  status: "healthy" | "unhealthy" | "unavailable";
  message: string;
  url?: string;
};

type HealthResponse = {
  status: string;
  services: {
    cerai_bot?: ServiceStatus;
    postgres?: ServiceStatus;
    redis?: ServiceStatus;
    mongodb?: ServiceStatus;
    ocr?: ServiceStatus;
    lora?: ServiceStatus;
  };
};

export default function AIPage() {
  const [health, setHealth] = useState<HealthResponse | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchHealth = async () => {
      try {
        const response = await fetch("/api/cerai/health");
        const data = await response.json();
        setHealth(data);
      } catch (error) {
        console.error("Error fetching health:", error);
      } finally {
        setLoading(false);
      }
    };

    fetchHealth();
    // Poll every 30 seconds
    const interval = setInterval(fetchHealth, 30000);
    return () => clearInterval(interval);
  }, []);

  const getStatusColor = (status?: string) => {
    if (!status) return "text-gray-400";
    switch (status) {
      case "healthy":
        return "text-green-400";
      case "unhealthy":
        return "text-yellow-400";
      case "unavailable":
        return "text-red-400";
      default:
        return "text-gray-400";
    }
  };

  const getStatusText = (status?: string) => {
    if (!status) return "Nieznany";
    switch (status) {
      case "healthy":
        return "Online";
      case "unhealthy":
        return "Problemy";
      case "unavailable":
        return "Niedostępny";
      default:
        return "Nieznany";
    }
  };

  return (
    <div className="p-6">
      <div className="mb-8">
        <h1 className="font-display text-4xl text-ivory-100">CerAI - Asystent AI</h1>
        <p className="mt-2 text-ivory-100/70">
          Inteligentny asystent do analizy dokumentów i zarządzania danymi
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-6">
        <div className="marble-card p-6">
          <h2 className="text-xl font-semibold text-ivory-100 mb-4">
            Asystent Księgowy
          </h2>
          <p className="text-ivory-100/70 mb-4">
            Analizuj faktury, paragony i dokumenty księgowe. Automatycznie wyciągaj dane
            i generuj raporty.
          </p>
          <ul className="space-y-2 text-sm text-ivory-100/60">
            <li>• Analiza faktur i paragonów (OCR)</li>
            <li>• Ekstrakcja danych z dokumentów</li>
            <li>• Generowanie raportów finansowych</li>
            <li>• Integracja z LoRA dla polskiego języka</li>
          </ul>
        </div>

        <div className="marble-card p-6">
          <h2 className="text-xl font-semibold text-ivory-100 mb-4">
            Zarządzanie Klientami
          </h2>
          <p className="text-ivory-100/70 mb-4">
            Wyszukuj informacje o klientach, analizuj dane i optymalizuj procesy.
          </p>
          <ul className="space-y-2 text-sm text-ivory-100/60">
            <li>• Wyszukiwanie klientów</li>
            <li>• Analiza danych klientów</li>
            <li>• Raportowanie aktywności</li>
            <li>• Optymalizacja procesów</li>
          </ul>
        </div>
      </div>

      <div className="marble-card p-6">
        <h2 className="text-xl font-semibold text-ivory-100 mb-4">
          Status Systemu
        </h2>
        {loading ? (
          <div className="text-center py-8 text-ivory-100/60">Ładowanie...</div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="p-4 bg-white/5 rounded-lg">
              <div className="text-sm text-ivory-100/60 mb-1">CerAI Bot</div>
              <div className={`text-lg font-semibold ${getStatusColor(health?.services.cerai_bot?.status)}`}>
                {getStatusText(health?.services.cerai_bot?.status)}
              </div>
              {health?.services.cerai_bot?.message && (
                <div className="text-xs text-ivory-100/40 mt-1">
                  {health.services.cerai_bot.message}
                </div>
              )}
            </div>
            <div className="p-4 bg-white/5 rounded-lg">
              <div className="text-sm text-ivory-100/60 mb-1">LoRA Service</div>
              <div className={`text-lg font-semibold ${getStatusColor(health?.services.lora?.status)}`}>
                {getStatusText(health?.services.lora?.status)}
              </div>
              {health?.services.lora?.message && (
                <div className="text-xs text-ivory-100/40 mt-1">
                  {health.services.lora.message}
                </div>
              )}
            </div>
            <div className="p-4 bg-white/5 rounded-lg">
              <div className="text-sm text-ivory-100/60 mb-1">OCR</div>
              <div className={`text-lg font-semibold ${getStatusColor(health?.services.ocr?.status)}`}>
                {getStatusText(health?.services.ocr?.status)}
              </div>
              {health?.services.ocr?.message && (
                <div className="text-xs text-ivory-100/40 mt-1">
                  {health.services.ocr.message}
                </div>
              )}
            </div>
            <div className="p-4 bg-white/5 rounded-lg">
              <div className="text-sm text-ivory-100/60 mb-1">PostgreSQL</div>
              <div className={`text-lg font-semibold ${getStatusColor(health?.services.postgres?.status)}`}>
                {getStatusText(health?.services.postgres?.status)}
              </div>
            </div>
            <div className="p-4 bg-white/5 rounded-lg">
              <div className="text-sm text-ivory-100/60 mb-1">Redis</div>
              <div className={`text-lg font-semibold ${getStatusColor(health?.services.redis?.status)}`}>
                {getStatusText(health?.services.redis?.status)}
              </div>
            </div>
            <div className="p-4 bg-white/5 rounded-lg">
              <div className="text-sm text-ivory-100/60 mb-1">MongoDB</div>
              <div className={`text-lg font-semibold ${getStatusColor(health?.services.mongodb?.status)}`}>
                {getStatusText(health?.services.mongodb?.status)}
              </div>
            </div>
          </div>
        )}
      </div>

      {/* CerAI Chat Widget */}
      <div className="mt-8">
        <CerAI botType="accounting" context="admin_ai_page" />
      </div>
    </div>
  );
}

