# TypeScript Frontend Monorepo

Цей репозиторій містить множинні фронтенд фреймворки, налаштовані для роботи в монопорії з спільними залежностями та конфігураціями.

## Структура проекту

```
├── shared/          # Спільні утиліти та конфігурації
├── angular/         # Angular 17 додаток
├── next/            # Next.js 14 додаток
├── nuxt/            # Nuxt 3 додаток
├── svelte/          # SvelteKit додаток
└── package.json     # Основний package.json з workspaces
```

## Доступні фреймворки

### 🅰️ Angular (17.x)
- **UI**: ng-zorro-antd, Angular Material
- **Графіки**: ngx-charts, Chart.js
- **Стан**: RxJS
- **Інтернаціоналізація**: @ngx-translate
- **3D**: Three.js

### ⚛️ Next.js (14.x)
- **UI**: Material-UI (MUI)
- **Стан**: Redux Toolkit, TanStack Query
- **Анімації**: Framer Motion
- **Графіки**: Recharts, Chart.js
- **Інтернаціоналізація**: react-i18next
- **3D**: Three.js

### 🟢 Nuxt (3.x)
- **UI**: Nuxt UI, Tailwind CSS
- **Стан**: Pinia
- **Графіки**: Chart.js, Vue Chart.js
- **Інтернаціоналізація**: @nuxtjs/i18n
- **3D**: Three.js

### 🟠 Svelte (4.x)
- **UI**: Skeleton UI, Tailwind CSS
- **Стан**: Svelte stores, TanStack Query
- **Графіки**: Chart.js
- **Інтернаціоналізація**: svelte-i18n
- **3D**: Three.js

## Спільні залежності

Всі фреймворки використовують спільні залежності з папки `shared/`:

- **3D**: Three.js
- **Графіки**: Chart.js
- **Стилі**: Tailwind CSS
- **Пост-процесинг**: PostCSS, Autoprefixer
- **Інструменти**: ESLint, Prettier, Stylelint

## Встановлення

```bash
# Встановити всі залежності
yarn install

# Або для конкретного workspace
yarn workspace angular-lib install
yarn workspace next-lib install
yarn workspace nuxt-lib install
yarn workspace svelte-lib install
```

## Розробка

### Запуск всіх проектів
```bash
yarn dev:all
```

### Запуск конкретного фреймворку

#### Angular
```bash
yarn workspace angular-lib dev
# або
cd angular && yarn dev
```

#### Next.js
```bash
yarn workspace next-lib dev
# або
cd next && yarn dev
```

#### Nuxt
```bash
yarn workspace nuxt-lib dev
# або
cd nuxt && yarn dev
```

#### Svelte
```bash
yarn workspace svelte-lib dev
# або
cd svelte && yarn dev
```

## Збірка

### Збірка всіх проектів
```bash
yarn build:all
```

### Збірка конкретного фреймворку
```bash
yarn workspace angular-lib build
yarn workspace next-lib build
yarn workspace nuxt-lib build
yarn workspace svelte-lib build
```

## Лінтинг та форматування

### Перевірка коду
```bash
yarn lint          # ESLint
yarn lint:css      # Stylelint
```

### Форматування
```bash
yarn format        # Prettier
```

### Перевірка форматування
```bash
yarn format:check
```

## Структура конфігурацій

### Спільні конфігурації (shared/)
- `.eslintrc` - ESLint конфігурація для всіх фреймворків
- `.prettierrc` - Prettier конфігурація
- `.stylelintrc` - Stylelint конфігурація
- `postcss.config.ts` - PostCSS конфігурація
- `tailwind.config.ts` - Tailwind CSS конфігурація

### Фреймворк-специфічні конфігурації
- `angular.json` - Angular CLI конфігурація
- `next.config.ts` - Next.js конфігурація
- `nuxt.config.ts` - Nuxt конфігурація
- `svelte.config.ts` - SvelteKit конфігурація

## Особливості

### 🔄 Спільні залежності
Всі фреймворки використовують спільні залежності, що забезпечує:
- Консистентність версій
- Зменшення розміру node_modules
- Спрощення оновлень

### 📦 Workspaces
Проект налаштований як Yarn workspace з:
- Спільним package-lock.json
- Ізольованими залежностями для кожного фреймворку
- Можливістю запуску команд для всіх workspace одночасно

### 🎨 Універсальні стилі
- Tailwind CSS для всіх фреймворків
- Спільна тема та кольорова схема
- PostCSS з автоматичними префіксами

### 🔧 Інструменти розробки
- TypeScript для всіх проектів
- ESLint з правилами для всіх фреймворків
- Prettier для форматування
- Stylelint для CSS
- Husky для git hooks

## Порти за замовчуванням

- Angular: http://localhost:4200
- Next.js: http://localhost:3000
- Nuxt: http://localhost:3000
- Svelte: http://localhost:5173

## Примітки

- Всі проекти налаштовані для TypeScript
- Використовуються сучасні версії фреймворків
- Конфігурації оптимізовані для продакшену
- Підтримка hot reload для всіх фреймворків
