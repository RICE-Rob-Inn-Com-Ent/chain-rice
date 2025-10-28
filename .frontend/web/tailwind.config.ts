import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./index.tsx",
    "./index.html",
    "./lib/**/*.{ts,tsx}",
    "./components/**/*.{ts,tsx}",
    "./molecules/**/*.{ts,tsx}",
    "./benchmark/**/*.{ts,tsx}",
  ],

  plugins: [require("@tailwindcss/forms"), require("@tailwindcss/typography")],
};

export default config;
