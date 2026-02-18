/** @type {import('tailwindcss').Config} */
module.exports = {
  darkMode: "class",
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./lib/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      fontFamily: {
        sans: ["Inter", "system-ui", "sans-serif"],
        display: ["var(--font-display)", "Playfair Display", "serif"],
      },
      colors: {
        obsidian: {
          50: "#f5f5f5",
          100: "#e7e7e7",
          200: "#cfcfcf",
          300: "#adadad",
          400: "#7f7f7f",
          500: "#525252",
          600: "#393939",
          700: "#242424",
          800: "#171717",
          900: "#0f0f0f",
          950: "#050505",
        },
        ember: {
          50: "#fff7ed",
          100: "#ffead5",
          200: "#fed0a8",
          300: "#fdb076",
          400: "#f6823c",
          500: "#eb520a",
          600: "#cb3906",
          700: "#a42d09",
          800: "#84250c",
          900: "#6b200d",
        },
        ivory: {
          50: "#fefcf7",
          100: "#f8f3e7",
        },
      },
      boxShadow: {
        "ceramix-glow": "0 25px 50px rgba(132, 37, 12, 0.3)",
      },
      backgroundImage: {
        "ceramix-hero": "radial-gradient(circle at top, rgba(132,37,12,0.55), rgba(5,5,5,0.95))",
        "ceramix-grid": "linear-gradient(rgba(255,255,255,0.04) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,0.04) 1px, transparent 1px)",
      },
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
  ],
};
