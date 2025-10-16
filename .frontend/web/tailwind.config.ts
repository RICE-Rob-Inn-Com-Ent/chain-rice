import type { Config } from 'tailwindcss';

const config: Config = {
  content: [
    './src/**/*.{js,ts,jsx,tsx,vue,svelte}',
    './components/**/*.{js,ts,jsx,tsx,vue,svelte}',
    './pages/**/*.{js,ts,jsx,tsx,vue,svelte}',
    './layouts/**/*.{js,ts,jsx,tsx,vue,svelte}',
    './app/**/*.{js,ts,jsx,tsx,vue,svelte}',
    './index.html',
  ],

  plugins: [
    require('@tailwindcss/forms'),
    require('@tailwindcss/typography'),
  ],
};

export default config;
