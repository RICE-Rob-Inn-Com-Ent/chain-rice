# Chain Rice Frontend - Styling System

A modern, comprehensive styling system built with **Tailwind CSS**, **React**, and **TypeScript**.

## 🎨 Features

### **Complete Design System**
- **Color Palette**: Primary, secondary, success, warning, error colors with full shade ranges
- **Typography**: Inter and JetBrains Mono fonts with carefully crafted scales
- **Spacing**: Consistent spacing system with custom additions
- **Shadows**: Soft shadows, glows, and elevation effects
- **Border Radius**: From subtle to dramatic rounded corners

### **Dark Mode Support**
- **Class-based**: Toggle between light and dark themes
- **System Preference**: Automatically detect user's system preference
- **Persistent**: Theme preference saved to localStorage
- **Complete Coverage**: All components support both themes

### **Animation System**
- **Smooth Transitions**: Consistent 200ms transitions
- **Custom Animations**: Fade, slide, bounce, pulse effects
- **Loading States**: Skeleton loaders and spinners
- **Micro-interactions**: Hover effects and state changes

### **Component Library**
- **Buttons**: 5 variants, 3 sizes, loading states, icons
- **Cards**: Flexible layouts with headers, bodies, footers
- **Inputs**: Labels, icons, validation states, helpers
- **Badges**: Status indicators and dot variants
- **Modals**: Accessible with backdrop blur and animations
- **Loading**: Spinners, skeletons, and loading cards

## 🚀 Quick Start

### Installation

```bash
cd frontend
npm install
```

### Development

```bash
npm run dev
```

### Build

```bash
npm run build
```

## 📁 Project Structure

```
frontend/
├── src/
│   ├── components/
│   │   └── ui/              # UI component library
│   │       ├── Button.tsx
│   │       ├── Card.tsx
│   │       ├── Input.tsx
│   │       ├── Badge.tsx
│   │       ├── Modal.tsx
│   │       └── Loading.tsx
│   ├── styles/
│   │   └── globals.css      # Global styles and Tailwind config
│   ├── utils/
│   │   └── cn.ts           # Class name utility
│   ├── hooks/
│   │   └── useTheme.ts     # Theme management hook
│   └── App.tsx             # Main application with examples
├── tailwind.config.js      # Tailwind configuration
├── postcss.config.js       # PostCSS configuration
└── package.json           # Dependencies and scripts
```

## 🎨 Design Tokens

### Colors

```css
/* Primary (Blue) */
--color-primary-50: #f0f9ff
--color-primary-500: #0ea5e9
--color-primary-900: #0c4a6e

/* Secondary (Purple) */
--color-secondary-50: #fdf4ff
--color-secondary-500: #d946ef
--color-secondary-900: #701a75

/* Success (Green) */
--color-success-500: #22c55e

/* Warning (Yellow) */
--color-warning-500: #f59e0b

/* Error (Red) */
--color-error-500: #ef4444
```

### Typography

```css
/* Font Families */
font-family: 'Inter', sans-serif;        /* UI Text */
font-family: 'JetBrains Mono', monospace; /* Code */

/* Font Sizes */
text-xs    → 0.75rem
text-sm    → 0.875rem
text-base  → 1rem
text-lg    → 1.125rem
text-xl    → 1.25rem
/* ... up to text-9xl */
```

## 🧩 Component Usage

### Button

```tsx
import Button from '@/components/ui/Button'

<Button variant="primary" size="lg" loading leftIcon={<Icon />}>
  Click me
</Button>
```

### Card

```tsx
import { Card, CardHeader, CardBody, CardFooter } from '@/components/ui/Card'

<Card hover padding="lg">
  <CardHeader divider>
    <h3>Card Title</h3>
  </CardHeader>
  <CardBody>
    Card content goes here
  </CardBody>
  <CardFooter divider>
    <Button>Action</Button>
  </CardFooter>
</Card>
```

### Input

```tsx
import Input from '@/components/ui/Input'

<Input
  label="Email"
  type="email"
  placeholder="john@example.com"
  leftIcon={<EmailIcon />}
  helper="We'll never share your email"
  error="Invalid email format"
/>
```

## 🎯 CSS Classes

### Layout Utilities

```css
.container-sm   → max-width: 672px
.container-md   → max-width: 896px
.container-lg   → max-width: 1152px
.container-xl   → max-width: 1280px
```

### Component Classes

```css
.btn            → Base button styles
.btn-primary    → Primary button variant
.card           → Base card styles
.card-hover     → Card with hover effects
.input          → Base input styles
.badge          → Base badge styles
.glass          → Glass morphism effect
.gradient-text  → Gradient text effect
```

### State Classes

```css
.focus-ring     → Focus ring styles
.loading-skeleton → Skeleton loading animation
.nav-link       → Navigation link styles
.divider        → Section divider
```

## 🌙 Dark Mode

Dark mode is implemented using Tailwind's `dark:` modifier:

```tsx
// Toggle dark mode
const { theme, setTheme, isDark } = useTheme()

// Component with dark mode styles
<div className="bg-white dark:bg-gray-900 text-gray-900 dark:text-gray-100">
  Content adapts to theme
</div>
```

## 📱 Responsive Design

All components are mobile-first and responsive:

```css
/* Mobile first */
.grid-cols-1 md:grid-cols-2 lg:grid-cols-3

/* Responsive spacing */
.px-4 sm:px-6 lg:px-8

/* Responsive text */
.text-sm sm:text-base lg:text-lg
```

## ⚡ Performance

- **Tree Shaking**: Only used Tailwind classes are included
- **Component Lazy Loading**: React.lazy for route-based splitting
- **Optimized Assets**: Vite handles asset optimization
- **CSS Purging**: Unused styles removed in production

## 🔧 Customization

### Adding New Colors

```js
// tailwind.config.js
module.exports = {
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#...',
          500: '#...',
          900: '#...',
        }
      }
    }
  }
}
```

### Custom Components

```css
/* globals.css */
@layer components {
  .btn-custom {
    @apply px-4 py-2 bg-brand-500 text-white rounded-lg;
  }
}
```

## 📚 Dependencies

### Core Dependencies
- **React 18**: Latest React with concurrent features
- **TypeScript**: Type safety and better DX
- **Vite**: Fast build tool and dev server

### Styling Dependencies
- **Tailwind CSS**: Utility-first CSS framework
- **Headless UI**: Accessible components
- **Heroicons**: Beautiful SVG icons
- **clsx**: Conditional class names
- **tailwind-merge**: Merge Tailwind classes intelligently

### Development Dependencies
- **ESLint**: Code linting
- **PostCSS**: CSS processing
- **Autoprefixer**: CSS vendor prefixes

## 🤝 Contributing

1. Follow the established design tokens
2. Ensure dark mode support for new components
3. Add proper TypeScript types
4. Include responsive design considerations
5. Test accessibility features

## 📄 License

This project is licensed under the MIT License.