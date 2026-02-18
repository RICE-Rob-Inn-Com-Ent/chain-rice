import type { Config } from "tailwindcss";

const meowtopiaColors = {
  graphite: {
    50: "#f8f9fa",
    100: "#ecf0f1",
    200: "#bdc3c7",
    300: "#95a5a6",
    400: "#7f8c8d",
    500: "#34495e",
    600: "#2C3E40",
    700: "#273E47",
    800: "#1e2a2e",
    900: "#17202a"
  },
  rudy: {
    50: "#fdf2e9",
    100: "#fae5d3",
    200: "#f5b7b1",
    300: "#f39c12",
    400: "#e67e22",
    500: "#E67E22",
    600: "#d35400",
    700: "#a04000",
    800: "#7d3c00",
    900: "#5a2c00"
  },
  zielony: {
    50: "#e8f5e8",
    100: "#c8e6c9",
    200: "#a5d6a7",
    300: "#81c784",
    400: "#66bb6a",
    500: "#27AE60",
    600: "#2e7d32",
    700: "#388e3c",
    800: "#1b5e20",
    900: "#0d4f14"
  },
  rescue: {
    50: "#f3f8f4",
    100: "#e3f0e6",
    200: "#c8e1cd",
    300: "#9fc9a7",
    400: "#6fab78",
    500: "#5A8B63",
    600: "#4a7352",
    700: "#3e5d44",
    800: "#344c39",
    900: "#2c3f30"
  },
  sky: {
    50: "#f4f7fc",
    100: "#e8f0f9",
    200: "#d6e4f4",
    300: "#b8d1ec",
    400: "#94b8e1",
    500: "#7B9BCF",
    600: "#6482bd",
    700: "#566faa",
    800: "#4a5c8b",
    900: "#3f4d6e"
  }
};

const config: Config = {
  darkMode: "class",
  content: [
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./lib/**/*.{js,ts,jsx,tsx,mdx}",
    "./pages/**/*.{js,ts,jsx,tsx,mdx}"
  ],
  theme: {
    extend: {
      colors: {
        ...meowtopiaColors,
        primary: meowtopiaColors.graphite[600],
        secondary: meowtopiaColors.rudy[500],
        accent: meowtopiaColors.zielony[500],
        'meo-grafit': meowtopiaColors.graphite[600],
        'meo-rudy': meowtopiaColors.rudy[500],
        'meo-zielony': meowtopiaColors.zielony[500],
        'meo-nature': '#A3D9A5',
        'meo-brown': {
          50: '#faf9f7',
          100: '#f5f3f0',
          200: '#e8e3db',
          300: '#d4cbc0',
          400: '#b8a995',
          500: '#9d8a6f',
          600: '#7d6b55',
          700: '#5a4d3f',
          800: '#3d342a',
          900: '#1f1a15',
        },
        'meo-bg': '#fffef9',
        'meo-accent': meowtopiaColors.rudy[500],
        'meo-primary': meowtopiaColors.graphite[600],
        'meo-beige': {
          50: '#fefcf9',
          100: '#faf7f0',
          200: '#f5ede0',
          300: '#e8d9c5',
          400: '#d9c7a5',
          500: '#c9b28f',
          600: '#b89d7a',
          700: '#9d8265',
          800: '#7d6852',
          900: '#3d342a',
        },
        'meo-cream': {
          50: '#fffef9',
          100: '#fff8e1',
          200: '#fff2cc',
          300: '#ffe8a3',
          400: '#ffd966',
          500: '#ffcc33',
          600: '#e6b82e',
          700: '#cc9929',
          800: '#b37a24',
          900: '#995c1f',
        },
        success: meowtopiaColors.zielony[500],
        warning: meowtopiaColors.rudy[500],
        danger: meowtopiaColors.rudy[600],
        info: meowtopiaColors.graphite[400]
      },
      fontFamily: {
        heading: ["'Poppins'", "'Inter'", "sans-serif"],
        sans: ["'Inter'", "'Roboto'", "system-ui", "sans-serif"],
        accent: ["'Dancing Script'", "cursive"],
        display: ["'Playfair Display'", "serif"]
      },
      boxShadow: {
        "soft": "0 4px 20px rgba(44, 62, 64, 0.15)",
        "medium": "0 8px 30px rgba(44, 62, 64, 0.20)",
        "large": "0 20px 60px rgba(44, 62, 64, 0.25)",
        "rudy": "0 8px 25px rgba(230, 126, 34, 0.25)",
        "zielony": "0 8px 25px rgba(39, 174, 96, 0.25)",
        "inner-soft": "inset 0 2px 4px rgba(44, 62, 64, 0.10)"
      },
      backgroundImage: {
        "hero-gradient": "linear-gradient(135deg, #262D37 0%, #343a40 50%, #495057 100%)",
        "card-gradient": "linear-gradient(145deg, rgba(253, 252, 251, 0.9), rgba(250, 248, 245, 0.7))",
        "warm-gradient": "linear-gradient(to bottom right, #fdfcfb, #f5f1eb)",
        "nature-gradient": "linear-gradient(135deg, #5A8B63 0%, #7B9BCF 50%, #D4722A 100%)",
        "donation-gradient": "linear-gradient(135deg, #f9a8d4, #e9d5ff, #99f6e4)"
      },
      animation: {
        "gentle-float": "gentle-float 6s ease-in-out infinite",
        "soft-pulse": "soft-pulse 3s ease-in-out infinite",
        "fade-in": "fade-in 0.6s ease-out forwards",
        "slide-up": "slide-up 0.8s ease-out forwards"
      },
      keyframes: {
        "gentle-float": {
          "0%, 100%": { transform: "translateY(0px)" },
          "50%": { transform: "translateY(-10px)" }
        },
        "soft-pulse": {
          "0%, 100%": { opacity: "0.8", transform: "scale(1)" },
          "50%": { opacity: "1", transform: "scale(1.02)" }
        },
        "fade-in": {
          "0%": { opacity: "0", transform: "translateY(20px)" },
          "100%": { opacity: "1", transform: "translateY(0)" }
        },
        "slide-up": {
          "0%": { opacity: "0", transform: "translateY(40px)" },
          "100%": { opacity: "1", transform: "translateY(0)" }
        }
      },
      spacing: {
        "18": "4.5rem",
        "88": "22rem",
        "112": "28rem",
        "128": "32rem"
      },
      borderRadius: {
        "4xl": "2rem",
        "5xl": "2.5rem"
      }
    }
  },
  plugins: [require("@tailwindcss/forms"), require("@tailwindcss/typography")]
};

export default config;
