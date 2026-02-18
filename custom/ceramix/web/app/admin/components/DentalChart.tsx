"use client";

import React, { useState, useEffect } from "react";
import { Eye, X } from "lucide-react";
import ToothSVG, { getToothType, ToothSurfaceData, Surface as SurfaceType } from "./teeth/ToothSVG";

type ToothNumber = 11 | 12 | 13 | 14 | 15 | 16 | 17 | 18 | 21 | 22 | 23 | 24 | 25 | 26 | 27 | 28 | 31 | 32 | 33 | 34 | 35 | 36 | 37 | 38 | 41 | 42 | 43 | 44 | 45 | 46 | 47 | 48;

type Surface = "PZ" | "BS" | "PM" | "PD" | "PI" | "PW";

type Category = "conservative" | "endo" | "prosthetics" | "surgery";

interface DentalCondition {
  id: string;
  name: string;
  color: string;
  category: Category;
  icon?: string;
}

interface ToothEntry {
  toothNumber: ToothNumber;
  surface?: Surface;
  category: Category;
  conditionType: string;
  notes?: string;
}

interface CustomEntry {
  toothNumber: ToothNumber;
  text: string;
}

interface DentalChartProps {
  patientId: string;
  visitId?: string;
  onSave?: () => void;
}

const CONDITIONS: Record<Category, DentalCondition[]> = {
  conservative: [
    { id: "caries", name: "próchnica", color: "#ef4444", category: "conservative" },
    { id: "filling", name: "wypełnienie", color: "#3b82f6", category: "conservative" },
    { id: "secondary_caries", name: "próchnica wtórna", color: "#60a5fa", category: "conservative" },
    { id: "dressing", name: "opatrunek", color: "#d97706", category: "conservative" },
    { id: "carious_spot", name: "plama próchnicowa", color: "#f472b6", category: "conservative" },
    { id: "non_carious", name: "ubyte niepróchnicowy", color: "#10b981", category: "conservative" },
    { id: "onlay_inlay", name: "onlay/inlay", color: "#8b5cf6", category: "conservative" },
    { id: "calculus", name: "kamień nazębny", color: "#6b7280", category: "conservative" },
    { id: "observation", name: "do obserwacji", color: "#9ca3af", category: "conservative", icon: "eye" },
  ],
  endo: [
    { id: "necrotic_pulp", name: "ząb z martwą miazgą", color: "#d1d5db", category: "endo" },
    { id: "endo_dressing", name: "opatrunek", color: "#e5e7eb", category: "endo" },
    { id: "filled_canals", name: "kanały wypełnione", color: "#f472b6", category: "endo" },
    { id: "underfilled_canals", name: "kanały niedopełniony", color: "#ec4899", category: "endo" },
    { id: "periapical_lesion", name: "zmiana okołowierzchołkowa", color: "#ef4444", category: "endo" },
    { id: "root_resection", name: "korzeń po resekcji", color: "#dc2626", category: "endo" },
    { id: "root_resorption", name: "resorpcja korzenia", color: "#9ca3af", category: "endo" },
    { id: "root_fracture", name: "złamanie korzenia", color: "#6b7280", category: "endo" },
  ],
  prosthetics: [
    { id: "bridge_pontic", name: "przęsło mostu", color: "#7c3aed", category: "prosthetics" },
    { id: "crown", name: "korona", color: "#1e40af", category: "prosthetics" },
    { id: "veneer", name: "licówka", color: "#eab308", category: "prosthetics" },
    { id: "implant", name: "implant", color: "#6b7280", category: "prosthetics" },
    { id: "root_post", name: "wkład korzeniowy", color: "#374151", category: "prosthetics" },
  ],
  surgery: [
    { id: "erupting", name: "ząb w trakcie wyrzynania", color: "#000000", category: "surgery" },
    { id: "missing", name: "brak zęba", color: "#000000", category: "surgery" },
    { id: "tooth_extraction", name: "ząb do ekstrakcji", color: "#ef4444", category: "surgery" },
    { id: "root_extraction", name: "korzeń do ekstrakcji", color: "#ef4444", category: "surgery" },
    { id: "extracted", name: "ekstrakcja zęba", color: "#dc2626", category: "surgery" },
  ],
};

const SURFACES: { value: Surface; label: string; fullName: string }[] = [
  { value: "PZ", label: "PZ", fullName: "POWIERZCHNIA ZUJĄCA" },
  { value: "BS", label: "BS", fullName: "BRZEG SIECZNY" },
  { value: "PM", label: "PM", fullName: "POWIERZCHNIA MEZIALNA" },
  { value: "PD", label: "PD", fullName: "POWIERZCHNIA DYSTALNA" },
  { value: "PI", label: "PI", fullName: "POWIERZCHNIA JĘZYKOWA/PODNIEBIENNA" },
  { value: "PW", label: "PW", fullName: "POWIERZCHNIA WARGOWA/POLICZKOWA" },
];

const UPPER_TEETH: ToothNumber[] = [18, 17, 16, 15, 14, 13, 12, 11, 21, 22, 23, 24, 25, 26, 27, 28];
const LOWER_TEETH: ToothNumber[] = [38, 37, 36, 35, 34, 33, 32, 31, 41, 42, 43, 44, 45, 46, 47, 48];

export default function DentalChart({ patientId, visitId, onSave }: DentalChartProps) {
  const [selectedTooth, setSelectedTooth] = useState<ToothNumber | null>(null);
  const [selectedCategory, setSelectedCategory] = useState<Category | null>(null);
  const [selectedCondition, setSelectedCondition] = useState<string | null>(null);
  const [selectedSurface, setSelectedSurface] = useState<Surface | null>(null);
  const [selectedRoot, setSelectedRoot] = useState<number | null>(null);
  const [customEntry, setCustomEntry] = useState("");
  const [entries, setEntries] = useState<ToothEntry[]>([]);
  const [customEntries, setCustomEntries] = useState<CustomEntry[]>([]);
  const [currentVisitId, setCurrentVisitId] = useState<string | null>(visitId || null);
  const [isSaving, setIsSaving] = useState(false);

  useEffect(() => {
    if (currentVisitId) {
      loadChartData();
    }
  }, [currentVisitId, patientId]);

  const loadChartData = async () => {
    try {
      const response = await fetch(`/api/dental-chart?patientId=${patientId}&visitId=${currentVisitId || ""}`);
      if (response.ok) {
        const data = await response.json();
        setEntries((data.entries || []).map((e: any) => ({
          toothNumber: e.toothNumber,
          surface: e.surface,
          category: e.category,
          conditionType: e.conditionType,
          notes: e.notes,
        })));
        setCustomEntries((data.customEntries || []).map((e: any) => ({
          toothNumber: e.toothNumber,
          text: e.text,
        })));
      }
    } catch (error) {
      console.error("Failed to load chart data:", error);
    }
  };

  const createOrGetVisit = async () => {
    if (currentVisitId) return currentVisitId;

    try {
      const response = await fetch("/api/dental-visits", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          patientId,
          visitDate: new Date().toISOString().split("T")[0],
        }),
      });

      if (response.ok) {
        const data = await response.json();
        setCurrentVisitId(data.visitId);
        return data.visitId;
      }
    } catch (error) {
      console.error("Failed to create visit:", error);
    }
    return null;
  };

  // Get number of roots for a tooth
  const getRootCount = (toothNumber: ToothNumber): number => {
    const toothType = getToothType(toothNumber);
    if (toothType === "upper_molar" || toothType === "lower_molar") return 3;
    if (toothType === "upper_premolar" || toothType === "lower_premolar") return 2;
    return 1; // incisors and canines
  };

  const handleToothClick = (toothNumber: ToothNumber) => {
    if (selectedTooth === toothNumber && !selectedSurface) {
      // If clicking same tooth and no surface selected, cycle through roots
      const rootCount = getRootCount(toothNumber);
      if (selectedRoot === null || selectedRoot >= rootCount) {
        setSelectedRoot(1);
      } else {
        setSelectedRoot(selectedRoot + 1);
      }
      setSelectedSurface(null);
    } else {
      setSelectedTooth(toothNumber);
      setSelectedSurface(null);
      // On first click, if tooth has roots, select first root immediately
      const rootCount = getRootCount(toothNumber);
      if (rootCount > 0) {
        setSelectedRoot(1);
      } else {
        setSelectedRoot(null);
      }
    }
  };

  const handleConditionSelect = async (conditionId: string) => {
    if (!selectedTooth) return;

    const condition = Object.values(CONDITIONS)
      .flat()
      .find((c) => c.id === conditionId);
    if (!condition) return;

    // If surface is not selected, auto-select first surface or don't proceed
    if (!selectedSurface) {
      return;
    }

    const visitId = await createOrGetVisit();
    if (!visitId) return;

    const newEntry: ToothEntry = {
      toothNumber: selectedTooth,
      surface: selectedSurface,
      category: condition.category,
      conditionType: conditionId,
    };

    try {
      setIsSaving(true);
      const response = await fetch("/api/dental-chart", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          visitId,
          patientId,
          entry: newEntry,
        }),
      });

      if (response.ok) {
        // Reload entries from server
        const dataResponse = await fetch(`/api/dental-chart?patientId=${patientId}&visitId=${visitId || ""}`);
        if (dataResponse.ok) {
          const data = await dataResponse.json();
          setEntries(data.entries.map((e: any) => ({
            toothNumber: e.toothNumber,
            surface: e.surface,
            category: e.category,
            conditionType: e.conditionType,
            notes: e.notes,
          })));
        }
        setSelectedCondition(null);
        // Don't clear selectedSurface - allow adding more conditions to same surface
      } else {
        const errorData = await response.json();
        alert(errorData.error || "Nie udało się zapisać wpisu.");
      }
    } catch (error) {
      console.error("Failed to save entry:", error);
      alert("Wystąpił błąd podczas zapisywania.");
    } finally {
      setIsSaving(false);
    }
  };

  const handleSaveCustomEntry = async () => {
    if (!selectedTooth || !customEntry.trim()) return;

    const visitId = await createOrGetVisit();
    if (!visitId) return;

    try {
      const response = await fetch("/api/dental-chart/custom", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          visitId,
          patientId,
          toothNumber: selectedTooth,
          customText: customEntry,
        }),
      });

      if (response.ok) {
        setCustomEntries([...customEntries, { toothNumber: selectedTooth, text: customEntry }]);
        setCustomEntry("");
      }
    } catch (error) {
      console.error("Failed to save custom entry:", error);
    }
  };

  const handleClearTooth = async () => {
    if (!selectedTooth || !currentVisitId) return;

    try {
      const response = await fetch("/api/dental-chart", {
        method: "DELETE",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          visitId: currentVisitId,
          patientId,
          toothNumber: selectedTooth,
        }),
      });

      if (response.ok) {
        setEntries(entries.filter((e) => e.toothNumber !== selectedTooth));
        setCustomEntries(customEntries.filter((e) => e.toothNumber !== selectedTooth));
      }
    } catch (error) {
      console.error("Failed to clear tooth:", error);
    }
  };

  const getToothEntries = (toothNumber: ToothNumber) => {
    return entries.filter((e) => e.toothNumber === toothNumber);
  };

  const getToothCustomEntries = (toothNumber: ToothNumber) => {
    return customEntries.filter((e) => e.toothNumber === toothNumber);
  };

  const getToothSurfaces = (toothNumber: ToothNumber): ToothSurfaceData[] => {
    const toothEntries = getToothEntries(toothNumber);
    const surfaces: ToothSurfaceData[] = [];
    
    toothEntries.forEach((entry) => {
      if (entry.surface) {
        const condition = Object.values(CONDITIONS)
          .flat()
          .find((c) => c.id === entry.conditionType);
        if (condition) {
          surfaces.push({
            surface: entry.surface as SurfaceType,
            color: condition.color,
            conditionType: condition.id,
          });
        }
      }
    });
    
    return surfaces;
  };

  const handleSurfaceClick = (toothNumber: ToothNumber, surface: SurfaceType) => {
    setSelectedTooth(toothNumber);
    setSelectedSurface(surface);
    setSelectedRoot(null); // Clear root selection when surface is selected
    // Automatically select the first condition if category is selected
    if (selectedCategory) {
      const conditions = CONDITIONS[selectedCategory];
      if (conditions.length > 0) {
        setSelectedCondition(conditions[0].id);
      }
    }
  };

  // Get BS center position for each tooth type (cx value in viewBox)
  const getBSCenterX = (toothType: ReturnType<typeof getToothType>): number => {
    switch (toothType) {
      case "upper_incisor":
      case "upper_canine":
      case "lower_incisor":
      case "lower_canine":
        return 30; // BS at cx=30
      case "upper_premolar":
      case "lower_premolar":
        return 35; // BS at cx=35
      case "upper_molar":
      case "lower_molar":
        return 40; // BS at cx=40
      default:
        return 40;
    }
  };

  // Calculate transform to center BS over the number
  // ViewBox is 0 0 80 200, center is 40
  // SVG width is 60px, so 1 viewBox unit = 60/80 = 0.75px
  // We translate first, then scale, so offset needs to account for scale
  // After scale(1.2), we want BS at center, so: offset * 1.2 = desired_position
  // desired_position = (40 - bsX) * 0.75, so offset = (40 - bsX) * 0.75 / 1.2
  const getBSCenterTransform = (toothType: ReturnType<typeof getToothType>): string => {
    const bsX = getBSCenterX(toothType);
    const viewBoxCenter = 40;
    const offset = (viewBoxCenter - bsX) * (60 / 80) / 1.2; // Translate before scale
    return `translateX(${offset}px) scale(1.2)`;
  };

  const renderTooth = (toothNumber: ToothNumber, isUpper: boolean) => {
    const isSelected = selectedTooth === toothNumber;
    const hasEntries = getToothEntries(toothNumber).length > 0 || getToothCustomEntries(toothNumber).length > 0;
    const toothType = getToothType(toothNumber);
    const surfaces = getToothSurfaces(toothNumber);
    const selectedSurfaceForThisTooth = isSelected ? selectedSurface : null;
    const selectedRootForThisTooth = isSelected ? selectedRoot : null;

    return (
      <div
        key={toothNumber}
        className={`relative transition-all flex flex-col items-center gap-0 ${
          isSelected ? "ring-2 ring-amber-500 rounded-lg" : ""
        }`}
        style={{ pointerEvents: "none", margin: 0, padding: 0, width: '60px' }}
      >
        <div className="relative flex justify-center items-center" style={{ pointerEvents: "none", margin: 0, padding: 0, width: '100%', overflow: 'visible' }}>
          <div style={{ 
            pointerEvents: "auto", 
            margin: '0 auto', 
            padding: 0, 
            transform: `${getBSCenterTransform(toothType)}${!isUpper ? ' translateY(-5px)' : ''}`, 
            transformOrigin: 'center' 
          }}>
            <ToothSVG
              toothNumber={toothNumber}
              toothType={toothType}
              surfaces={surfaces}
              isSelected={isSelected}
              onSurfaceClick={(surface) => {
                handleSurfaceClick(toothNumber, surface);
              }}
              onToothClick={() => {
                handleToothClick(toothNumber);
              }}
              width={60}
              height={80}
            />
          </div>
          {hasEntries && (
            <div className="absolute -top-1 -right-1 w-3 h-3 bg-amber-500 rounded-full border-2 border-obsidian-900" style={{ pointerEvents: "none" }} />
          )}
        </div>
        <div className="text-center text-[10px] font-semibold text-ivory-100 !m-0 !p-0" style={{ pointerEvents: "none", margin: 0, padding: 0, lineHeight: 1, marginTop: '-6px', marginBottom: 0, width: '100%' }}>{toothNumber}</div>
        {selectedSurfaceForThisTooth && (
          <div className="text-center text-[9px] font-semibold text-amber-400 !m-0 !p-0" style={{ pointerEvents: "none", margin: 0, padding: 0, lineHeight: 1, marginTop: '1px', width: '100%' }}>
            {SURFACES.find(s => s.value === selectedSurfaceForThisTooth)?.label || selectedSurfaceForThisTooth}
          </div>
        )}
        {selectedRootForThisTooth && (
          <div className="text-center text-[9px] font-semibold text-amber-400 !m-0 !p-0" style={{ pointerEvents: "none", margin: 0, padding: 0, lineHeight: 1, marginTop: '1px', width: '100%' }}>
            K{selectedRootForThisTooth}
          </div>
        )}
      </div>
    );
  };

  return (
    <div className="space-y-6">
      {/* Dental Chart */}
      <div className="bg-obsidian-900/50 border border-white/10 rounded-lg p-2 sm:p-4 md:p-6 lg:p-8 w-full overflow-x-auto">
        <style jsx>{`
          .tooth-svg {
            background-color: transparent;
          }
          .tooth-svg path {
            transition: opacity 0.2s;
          }
          .tooth-svg path:hover {
            opacity: 0.7;
          }
        `}</style>
        {/* Upper Arch */}
        <div className="flex justify-center mb-1 items-start min-w-fit" style={{ gap: 0, margin: 0, padding: 0 }}>
          {UPPER_TEETH.map((tooth, index) => (
            <React.Fragment key={tooth}>
              {renderTooth(tooth, true)}
              {/* Divider between quadrants 1 and 2 (after tooth 11) */}
              {tooth === 11 && (
                <div className="w-0.5 bg-ivory-100/30" style={{ height: '100px', alignSelf: 'stretch' }} />
              )}
            </React.Fragment>
          ))}
        </div>

        {/* Lower Arch */}
        <div className="flex justify-center items-start min-w-fit" style={{ gap: 0, margin: 0, padding: 0 }}>
          {LOWER_TEETH.map((tooth, index) => (
            <React.Fragment key={tooth}>
              {renderTooth(tooth, false)}
              {/* Divider between quadrants 3 and 4 (after tooth 31) */}
              {tooth === 31 && (
                <div className="w-0.5 bg-ivory-100/30" style={{ height: '100px', alignSelf: 'stretch' }} />
              )}
            </React.Fragment>
          ))}
        </div>

        {/* Side Indicators */}
        <div className="flex justify-between mt-2 text-xl sm:text-2xl font-bold text-ivory-100/60">
          <span>P</span>
          <span>L</span>
        </div>
      </div>

      {/* Bottom Panel */}
      {selectedTooth && (
        <>
          {/* Backdrop */}
          <div 
            className="fixed inset-0 bg-black/40 backdrop-blur-sm z-40 transition-opacity duration-300 ease-out"
            onClick={() => {
              setSelectedTooth(null);
              setSelectedCategory(null);
              setSelectedCondition(null);
              setSelectedSurface(null);
              setSelectedRoot(null);
            }}
          />
          {/* Panel */}
          <div className="fixed bottom-0 left-0 right-0 max-h-[60vh] bg-obsidian-800 border-t border-white/10 p-4 md:p-6 overflow-y-auto z-50 shadow-2xl animate-slide-up">
            <style jsx>{`
              @keyframes slide-up {
                from {
                  transform: translateY(100%);
                  opacity: 0;
                }
                to {
                  transform: translateY(0);
                  opacity: 1;
                }
              }
              .animate-slide-up {
                animation: slide-up 0.25s cubic-bezier(0.16, 1, 0.3, 1) forwards;
              }
            `}</style>
            <div className="max-w-7xl mx-auto">
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
              {/* Left Column - Info */}
              <div className="space-y-4">
                <div>
                  <h3 className="text-lg font-semibold text-ivory-100 mb-2">
                    Ząb: {selectedTooth}
                  </h3>
                  <p className="text-sm text-ivory-100/60 mb-2">
                    Kategoria: {selectedCategory ? (
                      <>
                        {selectedCategory === "conservative" ? "Stomatologia zachowawcza" :
                         selectedCategory === "endo" ? "Endo" :
                         selectedCategory === "prosthetics" ? "Protetyka" :
                         "Chirurgia"}
                        {selectedSurface && (
                          <> - <span className="text-amber-400 font-semibold">{SURFACES.find(s => s.value === selectedSurface)?.label || selectedSurface}</span> ({SURFACES.find(s => s.value === selectedSurface)?.fullName || selectedSurface})</>
                        )}
                        {selectedRoot && (
                          <> - <span className="text-amber-400 font-semibold">K{selectedRoot}</span></>
                        )}
                      </>
                    ) : "Brak"}
                  </p>
                </div>
              </div>

              {/* Second Column - Category Selection */}
              <div className="space-y-4">
                <div>
                  <h4 className="font-semibold text-ivory-100 mb-2 text-sm">Wybierz kategorię</h4>
                  <div className="space-y-2">
                    {Object.keys(CONDITIONS).map((cat) => (
                      <button
                        key={cat}
                        onClick={() => {
                          setSelectedCategory(cat as Category);
                          setSelectedCondition(null);
                        }}
                        className={`w-full text-left px-3 py-2 rounded text-sm ${
                          selectedCategory === cat
                            ? "bg-ember-500 text-white"
                            : "bg-white/5 text-ivory-100/70 hover:bg-white/10"
                        }`}
                      >
                        {cat === "conservative" && "Stomatologia zachowawcza"}
                        {cat === "endo" && "Endo"}
                        {cat === "prosthetics" && "Protetyka"}
                        {cat === "surgery" && "Chirurgia"}
                      </button>
                    ))}
                  </div>
                </div>

                {/* Surface Selection */}
                {selectedCategory && (
                  <div>
                    <h4 className="font-semibold text-ivory-100 mb-2 text-sm">Wybierz powierzchnię</h4>
                    <div className="grid grid-cols-3 gap-2">
                      {SURFACES.map((surface) => (
                        <button
                          key={surface.value}
                          onClick={() => setSelectedSurface(surface.value)}
                          className={`px-2 py-1 rounded text-xs ${
                            selectedSurface === surface.value
                              ? "bg-ember-500 text-white"
                              : "bg-white/5 text-ivory-100/70 hover:bg-white/10"
                          }`}
                        >
                          {surface.label}
                        </button>
                      ))}
                    </div>
                  </div>
                )}
              </div>

              {/* Third Column - Condition Selection */}
              {selectedCategory && (
                <div className="space-y-4">
                  <div>
                    <h4 className="font-semibold text-ivory-100 mb-2 text-sm">Wybierz stan</h4>
                    <div className="space-y-1 max-h-[300px] overflow-y-auto">
                      {CONDITIONS[selectedCategory].map((condition) => (
                        <button
                          key={condition.id}
                          onClick={() => handleConditionSelect(condition.id)}
                          className="w-full flex items-center gap-2 px-2 py-1.5 rounded text-xs bg-white/5 text-ivory-100/70 hover:bg-white/10"
                        >
                          <div
                            className="w-3 h-3 rounded flex-shrink-0"
                            style={{ backgroundColor: condition.color }}
                          />
                          <span className="truncate">{condition.name}</span>
                        </button>
                      ))}
                    </div>
                  </div>
                </div>
              )}

              {/* Right Column - Actions & Custom Entry */}
              <div className="space-y-4">
                {/* Custom Entry */}
                <div>
                  <h4 className="font-semibold text-ivory-100 mb-2 text-sm">Wpisy własne</h4>
                  <textarea
                    value={customEntry}
                    onChange={(e) => setCustomEntry(e.target.value)}
                    className="w-full h-20 bg-white/5 border border-white/10 rounded p-2 text-ivory-100 resize-none text-xs"
                    placeholder="Wpisz notatkę..."
                  />
                  <button
                    onClick={handleSaveCustomEntry}
                    className="mt-2 w-full px-3 py-1.5 bg-green-500 text-white rounded text-sm font-semibold hover:bg-green-600"
                  >
                    Zapisz wpis
                  </button>
                </div>

                {/* Action Buttons */}
                <div className="space-y-2 pt-2 border-t border-white/10">
                  <button
                    onClick={async () => {
                      setIsSaving(true);
                      await createOrGetVisit();
                      if (onSave) onSave();
                      setIsSaving(false);
                    }}
                    disabled={isSaving}
                    className="w-full px-3 py-2 bg-green-500 text-white rounded text-sm font-semibold hover:bg-green-600 disabled:opacity-50"
                  >
                    {isSaving ? "Zapisywanie..." : "Zapisz i zamknij"}
                  </button>
                  <div className="grid grid-cols-2 gap-2">
                    <button
                      onClick={() => {
                        const nextTooth = selectedTooth < 48 ? (selectedTooth + 1) as ToothNumber : 11;
                        setSelectedTooth(nextTooth);
                      }}
                      className="px-3 py-1.5 bg-green-500 text-white rounded text-xs font-semibold hover:bg-green-600"
                    >
                      Następny
                    </button>
                    <button
                      onClick={handleClearTooth}
                      className="px-3 py-1.5 bg-gray-500 text-white rounded text-xs font-semibold hover:bg-gray-600"
                    >
                      Wyczyść
                    </button>
                  </div>
                  <button
                    onClick={() => {
                      setSelectedTooth(null);
                      setSelectedCategory(null);
                      setSelectedCondition(null);
                      setSelectedSurface(null);
                      setSelectedRoot(null);
                    }}
                    className="w-full px-3 py-1.5 bg-red-500 text-white rounded text-sm font-semibold hover:bg-red-600 transition-colors"
                  >
                    Zamknij
                  </button>
                </div>
              </div>
            </div>
          </div>
        </div>
        </>
      )}
    </div>
  );
}

