export interface Theme {
  name: string;
  colors: {
    primary: string;
    secondary: string;
    background: string;
    surface: string;
    text: string;
    accent: string;
  };
  layout: "sidebar-left" | "sidebar-right" | "top-nav";
}

export type ThemeName = "default" | "dark-purple" | "cyber-blue" | "forest-green" | "sunset-orange";

