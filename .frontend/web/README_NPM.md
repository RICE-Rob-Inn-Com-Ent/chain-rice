# @rice-mono/ui-kit

> Reusable React UI components for Rice AI ecosystem

[![npm version](https://badge.fury.io/js/@rice-mono%2Fui-kit.svg)](https://www.npmjs.com/package/@rice-mono/ui-kit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

## 🎯 Overview

`@rice-mono/ui-kit` is a comprehensive React component library built for the Rice AI platform. It provides beautiful, accessible, and customizable components used across the GiPT-1 admin panel and marketing website.

## 📦 Installation

```bash
npm install @rice-mono/ui-kit
# or
yarn add @rice-mono/ui-kit
# or
pnpm add @rice-mono/ui-kit
```

## 🚀 Quick Start

```tsx
import React from 'react';
import { Button1, Header3, ThemeProvider } from '@rice-mono/ui-kit';
import '@rice-mono/ui-kit/styles';

function App() {
  return (
    <ThemeProvider>
      <Header3 />
      <Button1 onClick={() => alert('Clicked!')}>
        Click Me
      </Button1>
    </ThemeProvider>
  );
}
```

## 📚 Components

### Base Components

**Buttons (10 variants)**
```tsx
import { Button1, Button2, Button3 } from '@rice-mono/ui-kit';

<Button1>Primary Action</Button1>
<Button2>Secondary</Button2>
<Button3>Outlined</Button3>
```

**Headers (5 variants)**
```tsx
import { Header1, Header2, Header3 } from '@rice-mono/ui-kit';

<Header1 />  // Full hero header
<Header2 />  // Minimal header
<Header3 />  // With navigation
```

**Forms**
```tsx
import { Input, Textarea, Card } from '@rice-mono/ui-kit';

<Input placeholder="Enter text" />
<Textarea rows={4} />
<Card>Content here</Card>
```

### Layouts

```tsx
import { Header, Footer, Navigation, SideBar } from '@rice-mono/ui-kit';

<Header />
<SideBar />
<Navigation links={[...]} />
<Footer />
```

### Services

**Ollama Integration**
```tsx
import { getOllamaModels, pullModel } from '@rice-mono/ui-kit';

const models = await getOllamaModels();
await pullModel('mistral:7b');
```

**Ra (Stable Diffusion) Integration**
```tsx
import { checkRaHealth, generateImageWithRa } from '@rice-mono/ui-kit';

const health = await checkRaHealth();
const result = await generateImageWithRa({
  prompt: 'A beautiful sunset',
  steps: 30
});
```

### Hooks

**useOllama**
```tsx
import { useOllama } from '@rice-mono/ui-kit';

function MyComponent() {
  const { models, runningModels, isHealthy } = useOllama(3000);
  
  return (
    <div>
      {models.map(m => <div key={m.name}>{m.name}</div>)}
    </div>
  );
}
```

### Theme System

```tsx
import { ThemeProvider, useTheme } from '@rice-mono/ui-kit';
import { darkPurple, cyberBlue } from '@rice-mono/ui-kit/themes';

<ThemeProvider defaultTheme={darkPurple}>
  <App />
</ThemeProvider>

// In components
function MyComponent() {
  const { currentTheme, switchTheme } = useTheme();
  return <button onClick={() => switchTheme(cyberBlue)}>Switch</button>;
}
```

## 🎨 Theming

The library includes 5 built-in themes:

- `default` - Classic dark theme
- `darkPurple` - Purple gradient
- `cyberBlue` - Cyberpunk blue
- `forestGreen` - Natural green
- `sunsetOrange` - Warm orange

### Custom Themes

```tsx
import { Theme } from '@rice-mono/ui-kit';

const myTheme: Theme = {
  name: 'my-theme',
  colors: {
    primary: '#8b5cf6',
    secondary: '#ec4899',
    background: '#0f172a',
    surface: '#1e293b',
    text: '#f1f5f9',
    accent: '#06b6d4'
  }
};
```

## 🔧 Configuration

### Tailwind CSS

If you're using Tailwind in your project:

```ts
// tailwind.config.ts
import type { Config } from 'tailwindcss';

export default {
  content: [
    './src/**/*.{ts,tsx}',
    './node_modules/@rice-mono/ui-kit/**/*.{ts,tsx}'
  ],
  theme: {
    extend: {
      colors: {
        theme: {
          primary: 'var(--color-primary)',
          // ... theme variables
        }
      }
    }
  }
} satisfies Config;
```

### PostCSS

```ts
// postcss.config.ts
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {}
  }
};
```

## 📖 Full Documentation

Visit our [documentation site](https://rice-mono.github.io/ui-kit) for:

- Interactive component demos
- API reference
- Code examples
- Migration guides

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md).

```bash
git clone https://github.com/rice-mono/ui-kit
cd ui-kit
yarn install
yarn dev
```

## 📄 License

MIT © Rice-Mono Team

## 🔗 Links

- **Website**: https://rice-ai.com
- **Admin Panel**: Port 3001
- **Marketing**: Port 3002
- **GitHub**: https://github.com/rice-mono
- **NPM**: https://npmjs.com/package/@rice-mono/ui-kit

## 💬 Support

- GitHub Issues: [rice-mono/ui-kit/issues](https://github.com/rice-mono/ui-kit/issues)
- Email: hello@rice-ai.com
- Discord: [Join our community](https://discord.gg/rice-mono)

---

**Built with ❤️ by Code-Rice** • Powered by GiPT-1

