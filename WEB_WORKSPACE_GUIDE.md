# Rice Mono-repo: Web Workspace Guide

## Overview

Mono-repo z dwoma Yarn workspaces:

1. **@rice/ui-kit** (`.frontend/web/`) - Component library + Vite dev gallery (Port 3000)
2. **rice-web** (`.project/web/`) - Next.js production app (Port 3001)

## Architecture

```
rice-mono/
├── package.json           # Root workspace config
├── .yarnrc.yml            # Yarn configuration
├── .frontend/web/         # @rice/ui-kit (NPM package)
│   ├── lib/              # Reusable components (atoms, molecules)
│   ├── models/           # AI god demo UIs (6 models)
│   ├── benchmark/        # Performance tests
│   ├── src/              # Vite dev app (component gallery)
│   ├── index.html        # Vite template with SEO
│   ├── vite.config.ts    # Port 3000
│   └── package.json      # @rice/ui-kit
└── .project/web/          # rice-web (Next.js app)
    ├── app/
    │   ├── meta/         # SEO (manifest, robots, sitemap)
    │   ├── pages/        # Page components
    │   ├── routes/       # API handlers & utils
    │   ├── api/          # Next.js API routes
    │   ├── layout.tsx    # Root layout with fonts & metadata
    │   └── page.tsx      # Home page
    ├── public/           # Static assets
    ├── index.css         # Branding & CSS variables
    ├── index.html        # SEO meta tags
    ├── next.config.mjs   # Next.js config
    └── package.json      # rice-web
```

## Commands

### From Root (`/home/mrDinkelman/rice-mono/`):

```bash
# Start both servers simultaneously
yarn dev
# → Vite: http://localhost:3000 (component gallery)
# → Next.js: http://localhost:3001 (production app)

# Build both projects
yarn build

# Lint all workspaces
yarn lint

# Clean all workspaces
yarn clean

# Install dependencies
yarn install
```

### Individual Workspaces:

```bash
# Only Vite dev server
yarn workspace @rice/ui-kit dev

# Only Next.js dev server
yarn workspace rice-web dev

# Build specific workspace
yarn workspace @rice/ui-kit build
yarn workspace rice-web build
```

## Development Workflow

### 1. Component Development (Vite - Port 3000)

1. Start component gallery: `yarn workspace @rice/ui-kit dev`
2. Open `http://localhost:3000`
3. Navigate tabs:
   - **Components** - Browse and test lib/ components
   - **AI Models** - Test all 6 god model UIs
   - **Benchmarks** - Monitor performance
4. Make changes in `.frontend/web/lib/` or `.frontend/web/models/`
5. See instant HMR updates

### 2. Production App (Next.js - Port 3001)

1. Start Next.js: `yarn workspace rice-web dev`
2. Open `http://localhost:3001`
3. Edit pages in `.project/web/app/pages/`
4. Components auto-imported from `@rice/ui-kit`

### 3. Full Stack Development

```bash
# Start both at once
yarn dev

# Two browsers:
# - localhost:3000 → Component testing
# - localhost:3001 → Production app
```

## Importing from @rice/ui-kit

### In Next.js (.project/web/):

```typescript
// Import components
import { Header, Footer, Button, Card, GradientText } from "@rice/ui-kit/lib";

// Import AI models
import { BastetUI, ThothUI, RaUI } from "@rice/ui-kit/models";

// Import benchmarks
import { NetworkSpeed, ModelLatency } from "@rice/ui-kit/benchmark";

// Import styles
import "@rice/ui-kit/styles";
```

### Path Aliases (tsconfig.json):

```json
{
  "paths": {
    "@rice/ui-kit": ["../../.frontend/web"],
    "@rice/ui-kit/*": ["../../.frontend/web/*"]
  }
}
```

## Configuration Sharing

### Tailwind CSS

- **Base config**: `.frontend/web/tailwind.config.ts` (content paths only)
- **Extended config**: `.project/web/tailwind.config.ts` (extends base + adds project paths)
- **Branding/Theme**: `.project/web/index.css` (all CSS variables, colors, animations)

### PostCSS

- **Master**: `.frontend/web/postcss.config.ts` (postcss-preset-env, tailwindcss, autoprefixer)
- **Next.js**: `.project/web/postcss.config.ts` (re-exports from @rice/ui-kit)

## Deployment

### Docker Build (Next.js):

```bash
cd .project/
docker build -t rice-web -f Dockerfile ..

# Runs on port 3001
docker run -p 3001:3001 rice-web
```

The Dockerfile:

1. Installs root workspace dependencies
2. Copies both `.frontend/web` and `.project/web`
3. Builds Next.js with `@rice/ui-kit` workspace dependency
4. Creates standalone production image

### NPM Publishing (@rice/ui-kit):

```bash
cd .frontend/web/
yarn build
npm publish --access public
```

## File Structure Best Practices

### Component Library (`.frontend/web/`):

- `lib/atoms/` - Small, reusable UI primitives (Button, Input, Card)
- `lib/molecules/` - Composed components (Header, Navbar, ContactForm)
- `models/` - Full-page AI model interfaces
- `benchmark/` - Performance testing components
- `src/` - Dev gallery app (not published to npm)

### Next.js App (`.project/web/`):

- `app/pages/` - Page components (imported into app/page.tsx)
- `app/meta/` - SEO metadata exports (manifest, robots, sitemap)
- `app/routes/` - Shared route handlers (Metadata.ts, Install.ts)
- `app/api/` - Next.js API routes
- `index.css` - Project-specific branding (CSS variables)

## SEO Configuration

All SEO metadata is centralized in:

1. **index.html** - Static meta tags for initial load
2. **app/layout.tsx** - Next.js Metadata API for dynamic SEO
3. **app/routes/Metadata.ts** - Manifest, robots.txt, sitemap.xml generators
4. **app/meta/** - Next.js route handlers (re-export from routes/)

## Troubleshooting

### Yarn Install Errors

Make sure you're in root directory and run:

```bash
cd /home/mrDinkelman/rice-mono
yarn install
```

### Module Resolution

If imports fail, verify:

1. `yarn install` completed successfully
2. `.project/web/tsconfig.json` has correct paths to `@rice/ui-kit`
3. Symlinks created by Yarn in `node_modules/@rice/ui-kit`

### Port Conflicts

- Vite uses port **3000**
- Next.js uses port **3001**

Change ports in:

- `.frontend/web/vite.config.ts` (server.port)
- `.project/web/package.json` (scripts.dev `-p` flag)

## Contributing

1. Develop components in `.frontend/web/lib/`
2. Test in Vite gallery: `yarn workspace @rice/ui-kit dev`
3. Use in Next.js: `import from '@rice/ui-kit/lib'`
4. Build: `yarn build`

---

**Built with:** React 18, TypeScript 5, Tailwind CSS 3, Vite 5, Next.js 14
