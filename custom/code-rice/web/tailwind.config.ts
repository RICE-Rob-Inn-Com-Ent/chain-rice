import rootConfig from "../../../tailwind.config";

const voidPalette = {
  50: "#f4f5fb",
  100: "#e4e7f5",
  200: "#c6cae6",
  300: "#9ca0ca",
  400: "#6f75a7",
  500: "#4c4f84",
  600: "#323465",
  700: "#1f2047",
  800: "#111330",
  900: "#080a24",
  950: "#030515",
};

const ion = {
  100: "#ccfbff",
  200: "#99f6ff",
  300: "#5feeff",
  400: "#33e4ff",
  500: "#0fd6ff",
  600: "#00a9d4",
  700: "#007dbc",
};

const config = {
  ...rootConfig,
  content: [
    "./app/**/*.{ts,tsx}",
    "./app/**/*.{js,jsx}",
    "./components/**/*.{ts,tsx}",
    "./components/**/*.{js,jsx}",
    "./pages/**/*.{ts,tsx}",
    "./pages/**/*.{js,jsx}",
    "./src/**/*.{ts,tsx}",
    "./src/**/*.{js,jsx}",
  ],
  theme: {
    ...rootConfig.theme,
    extend: {
      ...rootConfig.theme?.extend,
      colors: {
        ...rootConfig.theme?.extend?.colors,
        void: voidPalette,
        ion,
        neon: {
          magenta: "#f000ff",
          cyan: "#00fff6",
          amber: "#f5d742",
        },
      },
      container: {
        center: true,
        padding: "1rem",
        screens: {
          "2xl": "1280px",
        },
      },
      fontFamily: {
        ...rootConfig.theme?.extend?.fontFamily,
        sans: [
          "var(--font-inter)",
          "var(--font-poppins)",
          "ui-sans-serif",
          "system-ui",
          "-apple-system",
          "Segoe UI",
          "Roboto",
          "Helvetica",
          "Arial",
          '"Apple Color Emoji"',
          '"Segoe UI Emoji"',
        ],
        display: ["var(--font-orbitron)", "var(--font-poppins)", "ui-sans-serif", "system-ui"],
      },
      borderRadius: {
        lg: "1rem",
        md: "0.75rem",
        sm: "0.5rem",
      },
      boxShadow: {
        ...rootConfig.theme?.extend?.boxShadow,
        neon: "0 0 30px rgba(0,255,255,0.35)",
        "neon-magenta": "0 0 30px rgba(240,0,255,0.3)",
      },
      backgroundImage: {
        ...rootConfig.theme?.extend?.backgroundImage,
        "gradient-radial": "radial-gradient(var(--tw-gradient-stops))",
        "gradient-conic": "conic-gradient(from 180deg at 50% 50%, var(--tw-gradient-stops))",
        "gradient-brand": "linear-gradient(110deg, #0f172a, #1f2047, #080a24)",
        "grid-noise": "linear-gradient(180deg, rgba(12,18,34,0.95), rgba(5,9,18,0.9))",
      },
      keyframes: {
        "fade-in-up": {
          "0%": { opacity: "0", transform: "translateY(20px)" },
          "100%": { opacity: "1", transform: "translateY(0)" },
        },
        "fade-in": {
          "0%": { opacity: "0" },
          "100%": { opacity: "1" },
        },
        "neon-pulse": {
          "0%, 100%": { opacity: "0.7" },
          "50%": { opacity: "1" },
        },
        "glow-pulse": {
          "0%, 100%": { boxShadow: "0 0 20px rgba(15, 214, 255, 0.3)" },
          "50%": { boxShadow: "0 0 40px rgba(15, 214, 255, 0.6)" },
        },
        "float": {
          "0%, 100%": { transform: "translateY(0px)" },
          "50%": { transform: "translateY(-10px)" },
        },
        "shimmer": {
          "0%": { backgroundPosition: "-1000px 0" },
          "100%": { backgroundPosition: "1000px 0" },
        },
      },
      animation: {
        "fade-in": "fade-in 0.8s ease-out forwards",
        "fade-in-up": "fade-in-up 0.8s ease-out forwards",
        "glow-pulse": "glow-pulse 3s ease-in-out infinite",
        "float": "float 6s ease-in-out infinite",
        "shimmer": "shimmer 3s linear infinite",
      },
    },
  },
  plugins: [],
};

export default config;

