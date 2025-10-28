import React, { createContext, useContext, useEffect, useState } from "react";
import { Theme, ThemeName, themes } from "../../themes";

interface ThemeContextType {
  theme: Theme;
  themeName: ThemeName;
  setTheme: (name: ThemeName) => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [themeName, setThemeName] = useState<ThemeName>(() => {
    const saved = localStorage.getItem("theme");
    return (saved as ThemeName) || "default";
  });

  const theme = themes[themeName];

  useEffect(() => {
    // Apply CSS variables to root
    const root = document.documentElement;
    root.style.setProperty("--color-primary", theme.colors.primary);
    root.style.setProperty("--color-secondary", theme.colors.secondary);
    root.style.setProperty("--color-background", theme.colors.background);
    root.style.setProperty("--color-surface", theme.colors.surface);
    root.style.setProperty("--color-text", theme.colors.text);
    root.style.setProperty("--color-accent", theme.colors.accent);

    // Save to localStorage
    localStorage.setItem("theme", themeName);
  }, [theme, themeName]);

  const setTheme = (name: ThemeName) => {
    setThemeName(name);
  };

  return <ThemeContext.Provider value={{ theme, themeName, setTheme }}>{children}</ThemeContext.Provider>;
};

export const useTheme = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error("useTheme must be used within ThemeProvider");
  }
  return context;
};
