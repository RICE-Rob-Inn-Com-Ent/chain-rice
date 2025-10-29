import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./index.html",
    "./index.tsx",
    "./src/**/*.{ts,tsx}",
    "../web/lib/**/*.{ts,tsx}", // Include shared ui-kit components
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

