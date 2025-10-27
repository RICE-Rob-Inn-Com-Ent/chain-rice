# @rice/ui-kit

Open-source React component library with AI model demos and performance benchmarks.

## Features

- 🧩 **Atomic Design** - Organized atoms and molecules
- 🤖 **AI Model Demos** - Interactive UIs for 6 AI gods (Bastet, Isis, Khnum, Maat, Ra, Thoth)
- ⚡ **Benchmarks** - Network speed, system performance, model latency tests
- 🎨 **Tailwind CSS** - Fully customizable with CSS variables
- 📦 **NPM Ready** - Publish to npm or use as workspace
- 🚀 **Vite Dev Server** - Lightning-fast HMR on port 3000

## Installation

### As NPM Package (planned):

```bash
npm install @rice/ui-kit
# or
yarn add @rice/ui-kit
```

### As Yarn Workspace (current):

Already configured in mono-repo at `.frontend/web/`

## Structure

```
@rice/ui-kit/
├── lib/                   # Reusable Components
│   ├── atoms/            # Basic UI elements
│   │   ├── Button.tsx
│   │   ├── Input.tsx
│   │   ├── Card.tsx
│   │   ├── GradientText.tsx
│   │   ├── Reveal.tsx
│   │   ├── Section.tsx
│   │   └── ThemeToggle.tsx
│   ├── molecules/        # Composed components
│   │   ├── Header.tsx
│   │   ├── Navbar.tsx
│   │   ├── Footer.tsx
│   │   ├── ContactForm.tsx
│   │   ├── GodsPanel.tsx
│   │   ├── LoRaTrainingPanel.tsx
│   │   ├── TechStackGrid.tsx
│   │   ├── PricingCalculator.tsx
│   │   └── ChatWidget.tsx
│   └── index.ts
├── models/                # AI God Demos
│   ├── BastetUI.tsx      # Computer Vision
│   ├── IsisUI.tsx        # Medical AI
│   ├── KhnumUI.tsx       # Financial Analysis
│   ├── MaatUI.tsx        # Legal AI
│   ├── RaUI.tsx          # Image Generation
│   ├── ThothUI.tsx       # Knowledge Assistant
│   └── index.ts
├── benchmark/             # Performance Tests
│   ├── NetworkSpeed.tsx
│   ├── SystemPerf.tsx
│   ├── ModelLatency.tsx
│   └── index.ts
├── src/                   # Vite App (Dev Gallery)
│   ├── main.tsx          # Entry point
│   ├── App.tsx           # Router with tabs
│   └── routes/
│       ├── ComponentsView.tsx
│       ├── ModelsView.tsx
│       └── BenchmarksView.tsx
├── index.css              # Styles export
├── index.html             # Dev server template (SEO)
├── tailwind.config.ts     # Base Tailwind config
├── postcss.config.ts      # PostCSS config
└── vite.config.ts         # Vite dev server (port 3000)
```

## Usage

### Import Components

```typescript
// Import from lib
import { Header, Footer, Button, Card, GradientText } from "@rice/ui-kit/lib";

// Import AI model UIs
import { BastetUI, ThothUI, RaUI } from "@rice/ui-kit/models";

// Import benchmarks
import { NetworkSpeed, ModelLatency } from "@rice/ui-kit/benchmark";

// Import styles
import "@rice/ui-kit/styles";
```

### Example

```tsx
import { Header, Button, GradientText } from "@rice/ui-kit/lib";

export default function MyApp() {
  return (
    <Header>
      <div className="p-8">
        <h1>
          <GradientText>Welcome to Rice</GradientText>
        </h1>
        <Button variant="gradient">Get Started</Button>
      </div>
    </Header>
  );
}
```

## Development

```bash
# Start dev gallery (Vite on port 3000)
yarn dev

# Build for production
yarn build

# Run tests
yarn test

# Lint & format
yarn lint
yarn format
```

## Exports

| Export     | Path                                 | Description          |
| ---------- | ------------------------------------ | -------------------- |
| Main       | `@rice/ui-kit` or `@rice/ui-kit/lib` | All components       |
| Models     | `@rice/ui-kit/models`                | AI god demos         |
| Benchmarks | `@rice/ui-kit/benchmark`             | Performance tests    |
| Styles     | `@rice/ui-kit/styles`                | CSS file             |
| Tailwind   | `@rice/ui-kit/tailwind`              | Base Tailwind config |
| PostCSS    | `@rice/ui-kit/postcss`               | PostCSS config       |

## Component Gallery

When running `yarn dev`, visit `http://localhost:3000` to see:

- **Components Tab** - Browse all atoms and molecules with live examples
- **AI Models Tab** - Interactive demos of all 6 god models
- **Benchmarks Tab** - Real-time performance monitoring

## License

MIT

## Author

Rice-Mono Team
