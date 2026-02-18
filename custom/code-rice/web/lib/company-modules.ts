/**
 * Company Modules definitions used by the Code Rice marketing pages.
 * Inspired by local IT companies from https://rybnickie.it/firmy.
 *
 * This file is intentionally self-contained so the web app does not depend on
 * the shared ui-kit package.
 */

export type ModuleCategory =
  | "AI & Training"
  | "Analytics"
  | "Medical & R&D"
  | "AI Automation"
  | "Collaboration"
  | "Logistics"
  | "Portfolio"
  | "DevOps"
  | "Industry 4.0"
  | "Medical Data"
  | "Freelancing"
  | "Communication"
  | "Marketing"
  | "Data Analytics";

export interface AICapabilities {
  prediction?: boolean;
  dataAnalysis?: boolean;
  automation?: boolean;
  nlp?: boolean;
  computerVision?: boolean;
  recommendations?: boolean;
  chatIntegration?: boolean;
  models?: string[];
}

export interface CompanyModule {
  id: string;
  name: string;
  category: ModuleCategory;
  description: string;
  inspiredBy: string;
  features: string[];
  aiCapabilities: AICapabilities;
  endpoint: string;
  isActive: boolean;
  icon?: string;
  color?: string;
}

export const COMPANY_MODULES: CompanyModule[] = [
  {
    id: "apject",
    name: "Performance Analyzer",
    category: "Analytics",
    description:
      "Narzędzie do audytu wydajności aplikacji webowych. Analizuje Lighthouse metrics, Core Web Vitals i generuje raporty z rekomendacjami optymalizacji.",
    inspiredBy: "Apject.io - młody zespół programistów i designerów",
    features: [
      "Audyty Lighthouse automatyczne",
      "Analiza Core Web Vitals",
      "Monitoring wydajności real-time",
      "Porównanie z konkurencją",
      "Raporty z rekomendacjami AI",
      "Testy wydajności frontendu",
    ],
    aiCapabilities: {
      dataAnalysis: true,
      prediction: true,
      recommendations: true,
      models: ["Maat"],
    },
    endpoint: "/api/modules/apject",
    isActive: true,
    icon: "mdi:speedometer",
    color: "#10B981",
  },
  {
    id: "biostat",
    name: "MedAI Research Center",
    category: "Medical & R&D",
    description:
      "Centrum badawczo-rozwojowe do projektów medycznych. AI do analizy danych klinicznych, statystyki medycznej i wsparcia badań naukowych.",
    inspiredBy: "Biostat - centrum badawczo-rozwojowe z systemami medycznymi",
    features: [
      "Analiza danych klinicznych",
      "Statystyka medyczna z AI",
      "Projekty badawcze B+R",
      "eCRF i zarządzanie badaniami",
      "Wizualizacje danych medycznych",
      "Raportowanie zgodne z regulacjami",
    ],
    aiCapabilities: {
      dataAnalysis: true,
      prediction: true,
      automation: true,
      nlp: true,
      models: ["Ra", "Thoth"],
    },
    endpoint: "/api/modules/biostat",
    isActive: true,
    icon: "mdi:flask",
    color: "#EC4899",
  },
  {
    id: "digitree",
    name: "Collaboration Hub",
    category: "Collaboration",
    description:
      "Hub do współpracy zespołowej. Kalendarz AI, zarządzanie projektami, spotkania i komunikacja zespołowa w jednym miejscu.",
    inspiredBy: "Digitree Group - grupa kapitałowa z rozwiązaniami IT",
    features: [
      "AI kalendarz i planowanie",
      "Zarządzanie projektami",
      "Video konferencje",
      "Współdzielone dokumenty",
      "Timeline projektów",
      "Integracje z narzędziami",
    ],
    aiCapabilities: {
      automation: true,
      recommendations: true,
      nlp: true,
      chatIntegration: true,
      models: ["Thoth", "Maat"],
    },
    endpoint: "/api/modules/digitree",
    isActive: true,
    icon: "mdi:account-group",
    color: "#F59E0B",
  },
  {
    id: "firetms",
    name: "Logistics Console",
    category: "Logistics",
    description:
      "System zarządzania transportem i logistyką. AI do optymalizacji tras, predykcji kosztów i monitoringu dostaw w czasie rzeczywistym.",
    inspiredBy: "fireTMS - cloudowy system do zarządzania transportem",
    features: [
      "Zarządzanie zleceniami transportowymi",
      "Optymalizacja tras AI",
      "Predykcja kosztów dostawy",
      "Monitoring GPS real-time",
      "Rozliczenia i faktury",
      "Integracje z telematyką",
    ],
    aiCapabilities: {
      prediction: true,
      automation: true,
      dataAnalysis: true,
      recommendations: true,
      models: ["Maat", "Ra"],
    },
    endpoint: "/api/modules/firetms",
    isActive: true,
    icon: "mdi:truck-fast",
    color: "#EF4444",
  },
  {
    id: "fireup",
    name: "Project Showcase",
    category: "Portfolio",
    description:
      "Platforma do prezentacji portfolio projektów. AI analizuje projekty, generuje case studies i pomaga w prezentacji osiągnięć.",
    inspiredBy: "fireup.pro - software house tworzący kompleksowe rozwiązania",
    features: [
      "Portfolio projektów",
      "Case studies z AI",
      "Analiza technologii użytych",
      "Metryki sukcesu projektu",
      "Galeria i media",
      "Eksport do PDF/prezentacji",
    ],
    aiCapabilities: {
      dataAnalysis: true,
      nlp: true,
      recommendations: true,
      models: ["Thoth"],
    },
    endpoint: "/api/modules/fireup",
    isActive: true,
    icon: "mdi:briefcase",
    color: "#06B6D4",
  },
  {
    id: "hostersi",
    name: "CloudOps Manager",
    category: "DevOps",
    description:
      "Platforma do zarządzania infrastrukturą cloud. DevOps automation, monitoring 24/7, backup i zarządzanie AWS/Azure/GCP.",
    inspiredBy: "Hostersi - SysOps/DevOps House specjalizujący się w cloud",
    features: [
      "Zarządzanie infrastrukturą cloud",
      "Monitoring 24/7",
      "Automatyczne backup i restore",
      "CI/CD pipelines",
      "Security scanning",
      "Cost optimization AI",
    ],
    aiCapabilities: {
      automation: true,
      prediction: true,
      dataAnalysis: true,
      recommendations: true,
      models: ["Maat", "Khnum"],
    },
    endpoint: "/api/modules/hostersi",
    isActive: true,
    icon: "mdi:server-network",
    color: "#3B82F6",
  },
  {
    id: "linkpoint",
    name: "Industrial AI Lab",
    category: "Industry 4.0",
    description:
      "Laboratorium AI dla przemysłu 4.0. Predykcja awarii maszyn, automatyzacja produkcji, IoT i cyfryzacja procesów przemysłowych.",
    inspiredBy: "LinkPoint - robotyka i software przemysłowy",
    features: [
      "Predykcja awarii maszyn",
      "Monitoring IoT w czasie rzeczywistym",
      "Automatyzacja procesów produkcji",
      "Cyfrowe bliźniaki (digital twins)",
      "Analiza efektywności OEE",
      "Integracja z PLC i SCADA",
    ],
    aiCapabilities: {
      prediction: true,
      automation: true,
      dataAnalysis: true,
      computerVision: true,
      models: ["Ra", "Maat"],
    },
    endpoint: "/api/modules/linkpoint",
    isActive: true,
    icon: "mdi:factory",
    color: "#64748B",
  },
  {
    id: "medifile",
    name: "Medical Data Hub",
    category: "Medical Data",
    description:
      "Hub do zarządzania dokumentacją medyczną. E-recepty, e-wizyty, EDM dla gabinetów lekarskich z AI do diagnostyki wspomagającej.",
    inspiredBy: "Medfile - program do dokumentacji medycznej",
    features: [
      "Elektroniczna dokumentacja medyczna",
      "E-recepty i e-zwolnienia",
      "E-wizyty lekarskie",
      "AI wspomaganie diagnostyki",
      "Historia choroby pacjenta",
      "Integracja z systemami NFZ",
    ],
    aiCapabilities: {
      nlp: true,
      dataAnalysis: true,
      recommendations: true,
      chatIntegration: true,
      models: ["Thoth", "Ra"],
    },
    endpoint: "/api/modules/medifile",
    isActive: true,
    icon: "mdi:hospital-box",
    color: "#DC2626",
  },
  {
    id: "nomonday",
    name: "Freelance Zone",
    category: "Freelancing",
    description:
      "Strefa freelancingu i zarządzania zadaniami. AI do matchingu projektów, time tracking, faktury i zarządzanie klientami.",
    inspiredBy: "NoMonday - agencja digitalna z zespołem freelancerów",
    features: [
      "Zarządzanie zadaniami freelance",
      "Time tracking i timesheet",
      "Faktury i rozliczenia",
      "Chat projektowy z AI",
      "Matching projektów AI",
      "Portfolio i oferty",
    ],
    aiCapabilities: {
      automation: true,
      recommendations: true,
      nlp: true,
      chatIntegration: true,
      models: ["Thoth", "Bastet"],
    },
    endpoint: "/api/modules/nomonday",
    isActive: true,
    icon: "mdi:laptop",
    color: "#A855F7",
  },
  {
    id: "serversms",
    name: "Comms API Center",
    category: "Communication",
    description:
      "Centrum API do komunikacji wielokanałowej. SMS, MMS, VMS, Push, Viber, RCS - wszystko w jednym API z AI personalizacją.",
    inspiredBy: "SerwerSMS - platforma do kampanii wielokanałowych",
    features: [
      "API SMS/MMS/VMS",
      "Push notifications",
      "Viber i RCS messaging",
      "Kampanie marketingowe AI",
      "Personalizacja wiadomości",
      "Analityka i raporty",
    ],
    aiCapabilities: {
      nlp: true,
      automation: true,
      recommendations: true,
      dataAnalysis: true,
      models: ["Thoth", "Bastet"],
    },
    endpoint: "/api/modules/serversms",
    isActive: true,
    icon: "mdi:message-text",
    color: "#14B8A6",
  },
  {
    id: "sixteractive",
    name: "Ad Performance Studio",
    category: "Marketing",
    description:
      "Studio optymalizacji reklam i SEO. AI analizuje kampanie Google Ads, Allegro Ads, generuje insights i optymalizuje wydatki reklamowe.",
    inspiredBy: "sixteractive - Certyfikowany Partner Allegro Ads",
    features: [
      "Kampanie Google Ads z AI",
      "Optymalizacja Allegro Ads",
      "SEO i analiza słów kluczowych",
      "A/B testing reklam",
      "Lighthouse dla konkurencji",
      "ROI prediction",
    ],
    aiCapabilities: {
      dataAnalysis: true,
      prediction: true,
      recommendations: true,
      automation: true,
      models: ["Maat", "Thoth"],
    },
    endpoint: "/api/modules/sixteractive",
    isActive: true,
    icon: "mdi:bullhorn",
    color: "#F97316",
  },
  {
    id: "spiid",
    name: "Data Warehouse Manager",
    category: "Data Analytics",
    description:
      "Manager hurtowni danych. AI do eksploracji danych, tworzenia dashboardów, predykcji trendów i wsparcia decyzji biznesowych.",
    inspiredBy: "SPIID - specjaliści od hurtowni danych",
    features: [
      "Hurtownia danych cloud",
      "Eksploracja danych z AI",
      "Dashboardy i wizualizacje",
      "Predykcja trendów biznesowych",
      "ETL automation",
      "Data quality monitoring",
    ],
    aiCapabilities: {
      dataAnalysis: true,
      prediction: true,
      recommendations: true,
      automation: true,
      models: ["Ra", "Maat", "Thoth"],
    },
    endpoint: "/api/modules/spiid",
    isActive: true,
    icon: "mdi:database",
    color: "#6366F1",
  },
];

export function getModuleById(id: string): CompanyModule | undefined {
  return COMPANY_MODULES.find((module) => module.id === id);
}

export function getModulesByCategory(category: ModuleCategory): CompanyModule[] {
  return COMPANY_MODULES.filter((module) => module.category === category);
}

export function getActiveModules(): CompanyModule[] {
  return COMPANY_MODULES.filter((module) => module.isActive);
}

export function getCategories(): ModuleCategory[] {
  return [...new Set(COMPANY_MODULES.map((module) => module.category))];
}

export function searchModules(query: string): CompanyModule[] {
  const lowerQuery = query.toLowerCase();
  return COMPANY_MODULES.filter(
    (module) =>
      module.name.toLowerCase().includes(lowerQuery) ||
      module.description.toLowerCase().includes(lowerQuery) ||
      module.features.some((feature) => feature.toLowerCase().includes(lowerQuery)) ||
      module.inspiredBy.toLowerCase().includes(lowerQuery),
  );
}




