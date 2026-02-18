"use client";

import { createContext, useContext, useState, useEffect, ReactNode } from "react";

type OpeningHours = {
  [key: string]: {
    open: string;
    close: string;
    closed: boolean;
  };
};

type Location = {
  id: string;
  name: string;
  address: string | null;
  city: string | null;
  opening_hours?: OpeningHours | null;
};

type LocationContextType = {
  selectedLocationId: string | null;
  setSelectedLocationId: (id: string | null) => void;
  locations: Location[];
  selectedLocation: Location | null;
  refreshLocations: () => Promise<void>;
  loading: boolean;
};

const LocationContext = createContext<LocationContextType | undefined>(undefined);

export function LocationProvider({ children }: { children: ReactNode }) {
  const [selectedLocationId, setSelectedLocationId] = useState<string | null>(null);
  const [locations, setLocations] = useState<Location[]>([]);
  const [loading, setLoading] = useState(true);

  const refreshLocations = async () => {
    try {
      const res = await fetch("/api/locations");
      if (res.ok) {
        const data = await res.json();
        // Parse opening_hours if it's a string
        const locs = (data.locations || []).map((loc: any) => ({
          ...loc,
          opening_hours: typeof loc.opening_hours === 'string' 
            ? JSON.parse(loc.opening_hours) 
            : loc.opening_hours,
        }));
        setLocations(locs);
        
        // Jeśli nie ma wybranej lokalizacji, ustaw pierwszą aktywną
        if (!selectedLocationId && locs.length > 0) {
          const firstActive = locs.find((l: Location & { active: boolean }) => l.active) || locs[0];
          if (firstActive) {
            setSelectedLocationId(firstActive.id);
            // Zapisz w localStorage
            localStorage.setItem("selectedLocationId", firstActive.id);
          }
        }
      }
    } catch (error) {
      console.error("Error fetching locations:", error);
    } finally {
      setLoading(false);
    }
  };

  // Get selected location with opening_hours
  const selectedLocation = locations.find(loc => loc.id === selectedLocationId) || null;

  useEffect(() => {
    // Sprawdź localStorage dla zapisanej lokalizacji
    const savedLocationId = localStorage.getItem("selectedLocationId");
    
    refreshLocations().then(() => {
      if (savedLocationId) {
        // Sprawdź czy zapisana lokalizacja nadal istnieje
        fetch("/api/locations")
          .then(res => res.json())
          .then(data => {
            const locs = data.locations || [];
            const exists = locs.find((l: Location) => l.id === savedLocationId);
            if (exists) {
              setSelectedLocationId(savedLocationId);
            } else if (locs.length > 0) {
              const firstActive = locs.find((l: Location & { active: boolean }) => l.active) || locs[0];
              if (firstActive) {
                setSelectedLocationId(firstActive.id);
                localStorage.setItem("selectedLocationId", firstActive.id);
              }
            }
          });
      }
    });
  }, []);

  useEffect(() => {
    // Zapisz wybór do localStorage
    if (selectedLocationId) {
      localStorage.setItem("selectedLocationId", selectedLocationId);
    }
  }, [selectedLocationId]);

  return (
    <LocationContext.Provider 
      value={{ 
        selectedLocationId, 
        setSelectedLocationId, 
        locations, 
        selectedLocation,
        refreshLocations,
        loading 
      }}
    >
      {children}
    </LocationContext.Provider>
  );
}

export function useLocation() {
  const context = useContext(LocationContext);
  if (!context) {
    throw new Error("useLocation must be used within LocationProvider");
  }
  return context;
}

