## Architektura (wielomodułowa)

- `react/`: Vite + React (JSX). Pliki: `index.html`, `src/main.jsx`, `vite.config.js`.
- `react-native/`: Expo + React Native. Pliki: `App.js`, `package.json`.
- `ts/`: prosta aplikacja TypeScript (kompilacja `tsc` -> `dist/`). Pliki: `src/index.ts`, `tsconfig.json`.
- `next/`: Next.js (pages/). Pliki: `pages/index.jsx`, `package.json`.
- `vue/`: Vite + Vue 3. Pliki: `index.html`, `src/main.js`, `vite.config.js`.
- `angular/`: minimalny bootstrap Angular. Pliki: `index.html`, `src/main.js`, `vite.config.js`.
- `styles/`: moduły styli współdzielone między przykładami (CSS/SCSS/SASS).
- `configs/`: wspólne konfiguracje narzędzi (Prettier, ESLint, Tailwind, PostCSS).

### Użycie w praktyce (case)

- React: tworzenie prostych komponentów i interakcji (formularze, HMR podczas dev).
- TS (CLI): narzędzia obsługujące wejście z argv, generatory kodu, integracje API.
- Next: SSR/SSG i hybrydowe renderowanie.
- Vue: lekkie SPA.
- Angular: SPA o wyższej złożoności i spójnej strukturze.
- React Native: prototypy mobilne i web (Expo Web) bez skomplikowanej konfiguracji.

### Rozszerzanie

- Dodaj testy (Vitest/Jest), ESLint/Prettier, i CI.
- Skonfiguruj workspace (yarn/pnpm) do wspólnego lint/test/build.
- Style modułowe znajdziesz w `styles/`. Konfiguracje narzędzi w `configs/` (Prettier, ESLint, Tailwind, PostCSS).
- Integracja SVG w React (Vite):
- URL import: `import logoUrl from './src/logo.svg'` → `<img src={logoUrl} />`

