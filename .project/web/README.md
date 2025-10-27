# RICE Web - Next.js Application

Production-ready Next.js application using `@rice/ui-kit` component library.

## Architecture

```
.project/web/               # Next.js App (Port 3001)
├── app/
│   ├── meta/              # SEO & Metadata
│   │   ├── manifest.ts
│   │   ├── robots.ts
│   │   └── sitemap.ts
│   ├── pages/             # Page Components
│   │   ├── Home.tsx
│   │   ├── About.tsx
│   │   ├── Service.tsx
│   │   ├── Contact.tsx
│   │   └── Pricing.tsx
│   ├── routes/            # API Route Handlers
│   │   ├── Metadata.ts
│   │   └── Install.ts
│   ├── api/               # Next.js API Routes
│   ├── layout.tsx         # Root Layout
│   └── page.tsx           # Home Page
├── public/                # Static Assets
├── index.css              # Global Styles & Branding
├── index.html             # SEO Meta Tags
├── next.config.mjs        # Next.js Configuration
└── package.json           # Dependencies

```

## Dependencies

- **@rice/ui-kit** (workspace) - Component library from `.frontend/web`
- **Next.js 14.2.6** - React framework
- **Tailwind CSS** - Utility-first CSS
- **Lucide React** - Icon library

## Development

```bash
# From root:
yarn dev              # Starts both Vite (3000) and Next.js (3001)

# From this directory:
yarn dev              # Start Next.js dev server on port 3001
yarn build            # Build for production
yarn start            # Start production server
yarn lint             # Run ESLint
yarn typecheck        # TypeScript type checking
```

## Imports

Import components from `@rice/ui-kit`:

```typescript
import { Header, Footer, Button, Card } from "@rice/ui-kit/lib";
import { BastetUI, ThothUI } from "@rice/ui-kit/models";
```

## Configuration

- **Tailwind**: Extends base config from `@rice/ui-kit/tailwind`
- **PostCSS**: Re-exports config from `@rice/ui-kit/postcss`
- **Branding**: All CSS variables in `index.css`

## Deployment

Build with Docker:

```bash
# From .project/:
docker build -t rice-web -f Dockerfile ..
docker run -p 3001:3001 rice-web
```

The Dockerfile uses multi-stage build with workspace dependencies.
