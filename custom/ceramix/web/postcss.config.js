/** PostCSS config for Ceramix web (Next.js)
 *  This JS version ensures Next.js picks up Tailwind in all environments
 *  (Next currently looks for postcss.config.js / .cjs by default).
 */

module.exports = {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};


