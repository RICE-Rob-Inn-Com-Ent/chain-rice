import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./index.tsx",
    "./index.html",
    "./app/**/*.{ts,tsx}",
    "./lib/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./molecules/**/*.{ts,tsx}",
    "./benchmark/**/*.{ts,tsx}",
    "./widget/**/*.{ts,tsx}",
  ],

  theme: {
    extend: {
      colors: {
        theme: {
          primary: "var(--color-primary)",
          secondary: "var(--color-secondary)",
          background: "var(--color-background)",
          surface: "var(--color-surface)",
          text: "var(--color-text)",
          accent: "var(--color-accent)",
        },
      },
    },
  },

  plugins: [require("@tailwindcss/forms"), require("@tailwindcss/typography")],
};

export default config;
