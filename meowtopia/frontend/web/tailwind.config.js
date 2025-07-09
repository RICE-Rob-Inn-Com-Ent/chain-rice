module.exports = {
  content: ["./public/**/*.html", "./src/**/*.{ts,tsx}"],
  theme: {
    extend: {
      colors: {
        primary: "#01634A",
        secondary: "#EABD6E",
        accent: "#67E8F9",
        info: "#0C0A09",
        base: "#FAFAF9",
      },
    },
    fontFamily: {
      sans: ["Inter", "ui-sans-serif", "system-ui", "sans-serif"],
      display: ["Montserrat", "ui-sans-serif", "system-ui"],
      mono: ["Fira Mono", "ui-monospace", "SFMono-Regular"],
    },
  },
  plugins: [
    require("@tailwindcss/forms"),
    require("@tailwindcss/typography"),
    require("@tailwindcss/aspect-ratio"),
    require("@tailwindcss/line-clamp"),
    require("@tailwindcss/container-queries"),
    require("tailwind-scrollbar"),
    require("tailwindcss-scroll-snap"),
    require("tailwindcss-fluid-type"),
    require("tailwindcss-children"),
    require("tailwindcss-logical"),
    require("tailwindcss-textshadow"),
  ],
};
