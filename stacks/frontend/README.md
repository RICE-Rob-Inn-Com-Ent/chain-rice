## JS rodzina (React, React Native, TS, Next, Vue, Angular)

W tym katalogu znajdziesz kilka minimalnych przykładów, każdy pokazuje inny styl pracy z JS:

- `react/`: React + Vite (JSX, bez TS) — SPA z HMR
- `react-native/`: Expo/React Native — mobile/web (Expo Web)
- `ts/`: TypeScript (CLI) — kompilacja do Node (dist/)
- `next/`: Next.js — SSR/SSG i routing plikowy
- `vue/`: Vue 3 + Vite — lekkie SPA
- `angular/`: Angular + Vite — ustrukturyzowane SPA
- `styles/`: moduły CSS/SCSS/SASS (wspólne przykłady styli)
- `configs/`: przykładowe konfiguracje Prettier/ESLint/Tailwind/PostCSS

### Uruchomienie

- React: `cd react && yarn && yarn dev`
- TS CLI: `cd ts && yarn && yarn build && yarn start`
- Next: `cd next && yarn && yarn dev`
- Vue: `cd vue && yarn && yarn dev`
- Angular: `cd angular && yarn && yarn dev`
- React Native (Expo): `cd react-native && yarn && yarn start`

Zobacz `ARCHITECTURE.md` po szczegóły struktury.

## Do czego najlepiej pasują te przykłady?

- React (JSX): szybkie prototypowanie UI, dev server z HMR.
- TypeScript (CLI): narzędzia i skrypty uruchamiane w Node.
- Next: SSR/SSG, routing plikowy i hybrydowy rendering.
- Vue: lekkie SPA z reaktywnym core i składnią szablonów.
- Angular: ustrukturyzowane SPA z DI i komponentami.
- React Native: szybkie prototypy mobilne (i web przez Expo).

## Kiedy rozważyć inne podejścia?

- SSR/duże aplikacje: Next.js/Nuxt.
- Aplikacje mobilne natywne: Flutter/React Native.
- Skrypty systemowe: Python/Go (deployment uproszczony).

## Oceny (1–5 gwiazdek)

- Skala: 1 = niskie/małe, 5 = wysokie/duże.
- Poziom trudności nauki: ★★★☆☆
- Ekosystem/biblioteki: ★★★★★
- Zastosowania w praktyce: ★★★★★
- Wydajność dev/build (Vite/tsc): ★★★★☆
- Narzędzia: ★★★★★ (yarn/pnpm, Vite, tsc)

## Style i Tailwind

- Moduły CSS/SCSS/SASS przeniesione do `styles/`.
- Przykład konfiguracji Tailwind/PostCSS w `configs/` (plik `tailwind.config.js`, `postcss.config.js`).

Jak użyć Tailwinda (skrót):

- W podprojekcie Vite dodaj `postcss.config.js` (kopiuj z `configs/`) i plik wejściowy CSS z dyrektywami Tailwinda:
  - utwórz `src/index.css` z: `@tailwind base; @tailwind components; @tailwind utilities;`
  - zaimportuj w wejściu aplikacji (np. `src/main.jsx`): `import './index.css'`
  - dopasuj `content` w `tailwind.config.js` (patrz `configs/tailwind.config.js`)

## Przykładowe biblioteki i narzędzia

- React: `react`, `react-dom`, Vite.
- TS: `typescript` (`tsc`), ts-node, esbuild/tsup (opcjonalnie).
- Jakość: ESLint, Prettier, Jest/Vitest.

## Jak zacząć (skrót)

- React: `cd react && yarn && yarn dev`
- TS CLI: `cd ts && yarn && yarn build && yarn start`
- Next: `cd next && yarn && yarn dev`
- Vue: `cd vue && yarn && yarn dev`
- Angular: `cd angular && yarn && yarn dev`
- React Native: `cd react-native && yarn && yarn start`

