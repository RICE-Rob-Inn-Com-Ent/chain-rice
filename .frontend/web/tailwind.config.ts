import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './index.tsx',
    './index.html',
    './**/*.{js,ts,jsx,tsx,html}',
  ],

  plugins: [require('@tailwindcss/forms'), require('@tailwindcss/typography')],
};

export default config;
