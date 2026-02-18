"use client";

import React from "react";

export type ToothType = 
  | "upper_incisor"    // 11, 12, 21, 22
  | "upper_canine"     // 13, 23
  | "upper_premolar"   // 14, 15, 24, 25
  | "upper_molar"      // 16, 17, 18, 26, 27, 28
  | "lower_incisor"    // 31, 32, 41, 42
  | "lower_canine"     // 33, 43
  | "lower_premolar"   // 34, 35, 44, 45
  | "lower_molar";     // 36, 37, 38, 46, 47, 48

export type Surface = "PZ" | "BS" | "PM" | "PD" | "PI" | "PW";

export interface ToothSurfaceData {
  surface: Surface;
  color?: string;
  conditionType?: string;
}

interface ToothSVGProps {
  toothNumber: number;
  toothType: ToothType;
  surfaces: ToothSurfaceData[];
  isSelected?: boolean;
  onSurfaceClick?: (surface: Surface) => void;
  onToothClick?: () => void;
  width?: number;
  height?: number;
}

// Map tooth number to tooth type
export function getToothType(toothNumber: number): ToothType {
  if (toothNumber >= 11 && toothNumber <= 12) return "upper_incisor";
  if (toothNumber >= 21 && toothNumber <= 22) return "upper_incisor";
  if (toothNumber === 13 || toothNumber === 23) return "upper_canine";
  if (toothNumber >= 14 && toothNumber <= 15) return "upper_premolar";
  if (toothNumber >= 24 && toothNumber <= 25) return "upper_premolar";
  if (toothNumber >= 16 && toothNumber <= 18) return "upper_molar";
  if (toothNumber >= 26 && toothNumber <= 28) return "upper_molar";
  if (toothNumber >= 31 && toothNumber <= 32) return "lower_incisor";
  if (toothNumber >= 41 && toothNumber <= 42) return "lower_incisor";
  if (toothNumber === 33 || toothNumber === 43) return "lower_canine";
  if (toothNumber >= 34 && toothNumber <= 35) return "lower_premolar";
  if (toothNumber >= 44 && toothNumber <= 45) return "lower_premolar";
  if (toothNumber >= 36 && toothNumber <= 38) return "lower_molar";
  if (toothNumber >= 46 && toothNumber <= 48) return "lower_molar";
  return "upper_incisor"; // default
}

// Upper Incisor (11, 12, 21, 22)
const UpperIncisorSVG: React.FC<{
  surfaces: ToothSurfaceData[];
  onSurfaceClick?: (surface: Surface) => void;
  onToothClick?: () => void;
  width: number;
  height: number;
}> = ({ surfaces, onSurfaceClick, onToothClick, width, height }) => {
  const getSurfaceColor = (surface: Surface) => {
    return surfaces.find(s => s.surface === surface)?.color || "transparent";
  };

  return (
    <svg 
      width={width} 
      height={height} 
      viewBox="0 0 80 200" 
      className="tooth-svg" 
      style={{ backgroundColor: "transparent", pointerEvents: "none" }}
      onClick={(e) => {
        if (e.target === e.currentTarget) {
          e.stopPropagation();
          onToothClick?.();
        }
      }}
    >
      {/* Root - Rounded shape - positioned HIGHER for upper teeth - moved closer to crown by 3 units */}
      <path
        d="M 30 39 Q 24 66.5 18 94 L 42 94 Q 36 66.5 30 39 Z"
        fill="none"
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onToothClick?.();
        }}
      />
      
      {/* Palatal surface (PI) - same dimensions as tooth 44 */}
      <ellipse
        cx="30"
        cy="106"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PI") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PI");
        }}
      />
      
      {/* Labial/Buccal surface (PW) - same dimensions as tooth 44 */}
      <ellipse
        cx="30"
        cy="154"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PW") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PW");
        }}
      />
      
      {/* Crown - Rounded shape divided into clear sections */}
      {/* Main crown - perfect circle (clickable as BS) - positioned LOWER for upper teeth */}
      {/* Mesial surface (PM) - same dimensions as tooth 44 */}
      <ellipse
        cx="8"
        cy="129"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PM") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PM");
        }}
      />
      <circle
        cx="30"
        cy="129"
        r="12"
        fill={getSurfaceColor("BS") || "#f3f4f6"}
        stroke="#9ca3af"
        strokeWidth="2.5"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("BS");
        }}
      />
      {/* Distal surface (PD) - same dimensions as tooth 44 */}
      <ellipse
        cx="52"
        cy="129"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PD") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PD");
        }}
      />
    </svg>
  );
};

// Upper Canine (13, 23)
const UpperCanineSVG: React.FC<{
  surfaces: ToothSurfaceData[];
  onSurfaceClick?: (surface: Surface) => void;
  onToothClick?: () => void;
  width: number;
  height: number;
}> = ({ surfaces, onSurfaceClick, onToothClick, width, height }) => {
  const getSurfaceColor = (surface: Surface) => {
    return surfaces.find(s => s.surface === surface)?.color || "transparent";
  };

  return (
    <svg 
      width={width} 
      height={height} 
      viewBox="0 0 80 200" 
      className="tooth-svg" 
      style={{ backgroundColor: "transparent", pointerEvents: "none" }}
      onClick={(e) => {
        if (e.target === e.currentTarget) {
          e.stopPropagation();
          onToothClick?.();
        }
      }}
    >
      {/* Root - Rounded shape - positioned HIGHER for upper teeth - moved closer to crown by 3 units */}
      <path
        d="M 30 39 Q 24 66.5 18 94 L 42 94 Q 36 66.5 30 39 Z"
        fill="none"
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onToothClick?.();
        }}
      />
      
      {/* Palatal surface (PI) - same dimensions as tooth 44 */}
      <ellipse
        cx="30"
        cy="106"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PI") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PI");
        }}
      />
      
      {/* Labial/Buccal surface (PW) - same dimensions as tooth 44 */}
      <ellipse
        cx="30"
        cy="154"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PW") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PW");
        }}
      />
      
      {/* Crown - Rounded with pointed top - positioned LOWER for upper teeth */}
      {/* Mesial surface (PM) - same dimensions as tooth 44 */}
      <ellipse
        cx="8"
        cy="129"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PM") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PM");
        }}
      />
      <circle
        cx="30"
        cy="129"
        r="12"
        fill={getSurfaceColor("BS") || "#f3f4f6"}
        stroke="#9ca3af"
        strokeWidth="2.5"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("BS");
        }}
      />
      {/* Distal surface (PD) - same dimensions as tooth 44 */}
      <ellipse
        cx="52"
        cy="129"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PD") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PD");
        }}
      />
    </svg>
  );
};

// Upper Premolar (14, 15, 24, 25)
const UpperPremolarSVG: React.FC<{
  surfaces: ToothSurfaceData[];
  onSurfaceClick?: (surface: Surface) => void;
  onToothClick?: () => void;
  width: number;
  height: number;
}> = ({ surfaces, onSurfaceClick, onToothClick, width, height }) => {
  const getSurfaceColor = (surface: Surface) => {
    return surfaces.find(s => s.surface === surface)?.color || "transparent";
  };

  return (
    <svg 
      width={width} 
      height={height} 
      viewBox="0 0 80 200" 
      className="tooth-svg" 
      style={{ backgroundColor: "transparent", pointerEvents: "none" }}
      onClick={(e) => {
        if (e.target === e.currentTarget) {
          e.stopPropagation();
          onToothClick?.();
        }
      }}
    >
      {/* Root - Two rounded shapes - positioned HIGHER for upper teeth - spread out by 2 units - moved closer to crown by 3 units */}
      <path
        d="M 24 39 Q 18 66.5 12 94 L 36 94 Q 30 66.5 24 39 Z"
        fill="none"
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onToothClick?.();
        }}
      />
      <path
        d="M 46 39 Q 40 66.5 34 94 L 58 94 Q 52 66.5 46 39 Z"
        fill="none"
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onToothClick?.();
        }}
      />
      
      {/* Palatal surface (PI) - positioned between roots and BS for upper premolars */}
      <ellipse
        cx="35"
        cy="106"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PI") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PI");
        }}
      />
      
      {/* Labial/Buccal surface (PW) - positioned between PI and BS for upper premolars */}
      <ellipse
        cx="35"
        cy="154"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PW") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PW");
        }}
      />
      
      {/* Crown - Rounded shape - positioned LOWER for upper teeth */}
      {/* Mesial surface (PM) - same dimensions as tooth 44 */}
      <ellipse
        cx="13"
        cy="129"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PM") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PM");
        }}
      />
      <circle
        cx="35"
        cy="129"
        r="12"
        fill={getSurfaceColor("BS") || "#f3f4f6"}
        stroke="#9ca3af"
        strokeWidth="2.5"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("BS");
        }}
      />
      {/* Distal surface (PD) - same dimensions as tooth 44 */}
      <ellipse
        cx="57"
        cy="129"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PD") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PD");
        }}
      />
    </svg>
  );
};

// Upper Molar (16, 17, 18, 26, 27, 28)
const UpperMolarSVG: React.FC<{
  surfaces: ToothSurfaceData[];
  onSurfaceClick?: (surface: Surface) => void;
  onToothClick?: () => void;
  width: number;
  height: number;
}> = ({ surfaces, onSurfaceClick, onToothClick, width, height }) => {
  const getSurfaceColor = (surface: Surface) => {
    return surfaces.find(s => s.surface === surface)?.color || "transparent";
  };

  return (
    <svg 
      width={width} 
      height={height} 
      viewBox="0 0 80 200" 
      className="tooth-svg" 
      style={{ backgroundColor: "transparent", pointerEvents: "none" }}
      onClick={(e) => {
        if (e.target === e.currentTarget) {
          e.stopPropagation();
          onToothClick?.();
        }
      }}
    >
      {/* Root - Three rounded shapes - positioned HIGHER for upper teeth - spread out by 6 units total - moved closer to crown by 3 units - side roots tilted outward */}
      {/* Left root - tilted slightly outward */}
      <path
        d="M 22 39 Q 17 66.5 11 94 L 31 94 Q 26 66.5 22 39 Z"
        fill="none"
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onToothClick?.();
        }}
      />
      {/* Center root - vertical */}
      <path
        d="M 40 39 Q 35 66.5 30 94 L 50 94 Q 45 66.5 40 39 Z"
        fill="none"
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onToothClick?.();
        }}
      />
      {/* Right root - tilted slightly outward */}
      <path
        d="M 58 39 Q 53 66.5 47 94 L 67 94 Q 62 66.5 58 39 Z"
        fill="none"
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onToothClick?.();
        }}
      />
      
      {/* Palatal surface (PI) - positioned between roots and BS for upper molars - moved toward root by 3 units */}
      <ellipse
        cx="40"
        cy="103"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PI") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PI");
        }}
      />
      
      {/* Labial/Buccal surface (PW) - positioned between PI and BS for upper molars */}
      <ellipse
        cx="40"
        cy="154"
        rx="25"
        ry="8"
        fill={getSurfaceColor("PW") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PW");
        }}
      />
      
      {/* Crown - Larger rounded shape - positioned LOWER for upper teeth */}
      {/* Mesial surface (PM) - same dimensions as tooth 44 */}
      <ellipse
        cx="18"
        cy="129"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PM") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PM");
        }}
      />
      <circle
        cx="40"
        cy="129"
        r="12"
        fill={getSurfaceColor("BS") || "#f3f4f6"}
        stroke="#9ca3af"
        strokeWidth="2.5"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("BS");
        }}
      />
      {/* Distal surface (PD) - same dimensions as tooth 44 */}
      <ellipse
        cx="62"
        cy="129"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PD") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PD");
        }}
      />
    </svg>
  );
};

// Lower Incisor (31, 32, 41, 42) - odwrócony
const LowerIncisorSVG: React.FC<{
  surfaces: ToothSurfaceData[];
  onSurfaceClick?: (surface: Surface) => void;
  onToothClick?: () => void;
  width: number;
  height: number;
}> = ({ surfaces, onSurfaceClick, onToothClick, width, height }) => {
  const getSurfaceColor = (surface: Surface) => {
    return surfaces.find(s => s.surface === surface)?.color || "transparent";
  };

  return (
    <svg 
      width={width} 
      height={height} 
      viewBox="0 0 80 200" 
      className="tooth-svg" 
      style={{ backgroundColor: "transparent", pointerEvents: "none" }}
      onClick={(e) => {
        if (e.target === e.currentTarget) {
          e.stopPropagation();
          onToothClick?.();
        }
      }}
    >
      {/* Crown - Rounded shape (inverted) - positioned HIGHER for lower teeth */}
      {/* Mesial surface (PM) - same dimensions as tooth 44 */}
      <ellipse
        cx="8"
        cy="89"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PM") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PM");
        }}
      />
      <circle
        cx="30"
        cy="89"
        r="12"
        fill={getSurfaceColor("BS") || "#f3f4f6"}
        stroke="#9ca3af"
        strokeWidth="2.5"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("BS");
        }}
      />
      {/* Distal surface (PD) - same dimensions as tooth 44 */}
      <ellipse
        cx="52"
        cy="89"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PD") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PD");
        }}
      />
      
      {/* Lingual surface (PI) - same dimensions as tooth 44 */}
      <ellipse
        cx="30"
        cy="112"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PI") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PI");
        }}
      />
      
      {/* Labial/Buccal surface (PW) - same dimensions as tooth 44 */}
      <ellipse
        cx="30"
        cy="67"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PW") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PW");
        }}
      />
      
      {/* Root - Rounded shape - positioned LOWER for lower teeth - point down - moved closer to crown by 3 units */}
      <path
        d="M 30 179 Q 24 151.5 18 124 L 42 124 Q 36 151.5 30 179 Z"
        fill="none"
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onToothClick?.();
        }}
      />
    </svg>
  );
};

// Lower Canine (33, 43) - odwrócony
const LowerCanineSVG: React.FC<{
  surfaces: ToothSurfaceData[];
  onSurfaceClick?: (surface: Surface) => void;
  onToothClick?: () => void;
  width: number;
  height: number;
}> = ({ surfaces, onSurfaceClick, onToothClick, width, height }) => {
  const getSurfaceColor = (surface: Surface) => {
    return surfaces.find(s => s.surface === surface)?.color || "transparent";
  };

  return (
    <svg 
      width={width} 
      height={height} 
      viewBox="0 0 80 200" 
      className="tooth-svg" 
      style={{ backgroundColor: "transparent", pointerEvents: "none" }}
      onClick={(e) => {
        if (e.target === e.currentTarget) {
          e.stopPropagation();
          onToothClick?.();
        }
      }}
    >
      {/* Crown - Rounded with pointed bottom - positioned HIGHER for lower teeth */}
      {/* Mesial surface (PM) - same dimensions as tooth 44 */}
      <ellipse
        cx="8"
        cy="89"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PM") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PM");
        }}
      />
      <circle
        cx="30"
        cy="89"
        r="12"
        fill={getSurfaceColor("BS") || "#f3f4f6"}
        stroke="#9ca3af"
        strokeWidth="2.5"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("BS");
        }}
      />
      {/* Distal surface (PD) - same dimensions as tooth 44 */}
      <ellipse
        cx="52"
        cy="89"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PD") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PD");
        }}
      />
      
      {/* Lingual surface (PI) - same dimensions as tooth 44 */}
      <ellipse
        cx="30"
        cy="112"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PI") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PI");
        }}
      />
      
      {/* Labial/Buccal surface (PW) - same dimensions as tooth 44 */}
      <ellipse
        cx="30"
        cy="67"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PW") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PW");
        }}
      />
      
      {/* Root - Rounded shape - positioned LOWER for lower teeth - point down - moved closer to crown by 3 units */}
      <path
        d="M 30 179 Q 24 151.5 18 124 L 42 124 Q 36 151.5 30 179 Z"
        fill="none"
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onToothClick?.();
        }}
      />
    </svg>
  );
};

// Lower Premolar (34, 35, 44, 45) - odwrócony
const LowerPremolarSVG: React.FC<{
  surfaces: ToothSurfaceData[];
  onSurfaceClick?: (surface: Surface) => void;
  onToothClick?: () => void;
  width: number;
  height: number;
}> = ({ surfaces, onSurfaceClick, onToothClick, width, height }) => {
  const getSurfaceColor = (surface: Surface) => {
    return surfaces.find(s => s.surface === surface)?.color || "transparent";
  };

  return (
    <svg 
      width={width} 
      height={height} 
      viewBox="0 0 80 200" 
      className="tooth-svg" 
      style={{ backgroundColor: "transparent", pointerEvents: "none" }}
      onClick={(e) => {
        if (e.target === e.currentTarget) {
          e.stopPropagation();
          onToothClick?.();
        }
      }}
    >
      {/* Crown - Rounded shape (inverted) - positioned HIGHER for lower teeth */}
      {/* Mesial surface (PM) - left side of BS */}
      <ellipse
        cx="13"
        cy="89"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PM") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PM");
        }}
      />
      <circle
        cx="35"
        cy="89"
        r="12"
        fill={getSurfaceColor("BS") || "#f3f4f6"}
        stroke="#9ca3af"
        strokeWidth="2.5"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("BS");
        }}
      />
      {/* Distal surface (PD) - right side of BS */}
      <ellipse
        cx="57"
        cy="89"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PD") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PD");
        }}
      />
      
      {/* Lingual surface (PI) - positioned between BS and roots for lower premolars */}
      <ellipse
        cx="35"
        cy="112"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PI") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PI");
        }}
      />
      
      {/* Labial/Buccal surface (PW) - positioned between BS and PI for lower premolars */}
      <ellipse
        cx="35"
        cy="67"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PW") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PW");
        }}
      />
      
      {/* Root - Two rounded shapes - positioned LOWER for lower teeth - point down - spread out by 2 units - moved closer to crown by 3 units */}
      <path
        d="M 24 179 Q 18 151.5 12 124 L 36 124 Q 30 151.5 24 179 Z"
        fill="none"
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onToothClick?.();
        }}
      />
      <path
        d="M 46 179 Q 40 151.5 34 124 L 58 124 Q 52 151.5 46 179 Z"
        fill="none"
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onToothClick?.();
        }}
      />
    </svg>
  );
};

// Lower Molar (36, 37, 38, 46, 47, 48) - odwrócony
const LowerMolarSVG: React.FC<{
  surfaces: ToothSurfaceData[];
  onSurfaceClick?: (surface: Surface) => void;
  onToothClick?: () => void;
  width: number;
  height: number;
}> = ({ surfaces, onSurfaceClick, onToothClick, width, height }) => {
  const getSurfaceColor = (surface: Surface) => {
    return surfaces.find(s => s.surface === surface)?.color || "transparent";
  };

  return (
    <svg 
      width={width} 
      height={height} 
      viewBox="0 0 80 200" 
      className="tooth-svg" 
      style={{ backgroundColor: "transparent", pointerEvents: "none" }}
      onClick={(e) => {
        if (e.target === e.currentTarget) {
          e.stopPropagation();
          onToothClick?.();
        }
      }}
    >
      {/* Crown - Larger rounded shape (inverted) - positioned HIGHER for lower teeth */}
      {/* Mesial surface (PM) - same dimensions as tooth 44 */}
      <ellipse
        cx="18"
        cy="89"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PM") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PM");
        }}
      />
      <circle
        cx="40"
        cy="89"
        r="12"
        fill={getSurfaceColor("BS") || "#f3f4f6"}
        stroke="#9ca3af"
        strokeWidth="2.5"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("BS");
        }}
      />
      {/* Distal surface (PD) - same dimensions as tooth 44 */}
      <ellipse
        cx="62"
        cy="89"
        rx="8"
        ry="22"
        fill={getSurfaceColor("PD") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PD");
        }}
      />
      
      {/* Lingual surface (PI) - same dimensions as tooth 44 */}
      <ellipse
        cx="40"
        cy="112"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PI") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PI");
        }}
      />
      
      {/* Labial/Buccal surface (PW) - same dimensions as tooth 44 */}
      <ellipse
        cx="40"
        cy="67"
        rx="22"
        ry="8"
        fill={getSurfaceColor("PW") || "transparent"}
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onSurfaceClick?.("PW");
        }}
      />
      
      {/* Root - Two rounded shapes - positioned LOWER for lower teeth - point down - moved toward center by 3 units - moved closer to crown by 3 units */}
      <path
        d="M 28 179 Q 22 151.5 16 124 L 40 124 Q 34 151.5 28 179 Z"
        fill="none"
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onToothClick?.();
        }}
      />
      <path
        d="M 52 179 Q 46 151.5 40 124 L 64 124 Q 58 151.5 52 179 Z"
        fill="none"
        stroke="#9ca3af"
        strokeWidth="2"
        style={{ pointerEvents: "all" }}
        className="cursor-pointer hover:opacity-80"
        onClick={(e) => {
          e.stopPropagation();
          onToothClick?.();
        }}
      />
    </svg>
  );
};

export default function ToothSVG({
  toothNumber,
  toothType,
  surfaces,
  isSelected = false,
  onSurfaceClick,
  onToothClick,
  width = 60,
  height = 80,
}: ToothSVGProps) {
  const props = { surfaces, onSurfaceClick, onToothClick, width, height };

  switch (toothType) {
    case "upper_incisor":
      return <UpperIncisorSVG {...props} />;
    case "upper_canine":
      return <UpperCanineSVG {...props} />;
    case "upper_premolar":
      return <UpperPremolarSVG {...props} />;
    case "upper_molar":
      return <UpperMolarSVG {...props} />;
    case "lower_incisor":
      return <LowerIncisorSVG {...props} />;
    case "lower_canine":
      return <LowerCanineSVG {...props} />;
    case "lower_premolar":
      return <LowerPremolarSVG {...props} />;
    case "lower_molar":
      return <LowerMolarSVG {...props} />;
    default:
      return <UpperIncisorSVG {...props} />;
  }
}

