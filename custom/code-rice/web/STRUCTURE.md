# Struktura Projektu - Atomic Design

Projekt został zreorganizowany zgodnie z wzorcem **Atomic Design** i najlepszymi praktykami Next.js App Router.

## 📁 Struktura Katalogów

```
.project/web/
├── app/                    # Next.js App Router (tylko routing i metadata)
│   ├── page.tsx           # → importuje z pages/HomePage.tsx
│   ├── about/
│   │   └── page.tsx       # → importuje z pages/AboutPage.tsx
│   ├── services/
│   │   └── page.tsx       # → importuje z pages/ServicesPage.tsx
│   ├── team/
│   │   └── page.tsx       # → importuje z pages/TeamPage.tsx
│   ├── api/               # API routes
│   └── layout.tsx         # Root layout z nawigacją i footerem
│
├── pages/                  # Komponenty stron (logika biznesowa)
│   ├── HomePage.tsx
│   ├── AboutPage.tsx
│   ├── ServicesPage.tsx
│   └── TeamPage.tsx
│
├── lib/                    # Biblioteka komponentów (Atomic Design)
│   ├── atoms/             # Bazowe, atomowe komponenty
│   │   ├── GradientText.tsx
│   │   ├── Reveal.tsx
│   │   ├── Section.tsx
│   │   ├── ThemeToggle.tsx
│   │   ├── LogoWall.tsx
│   │   └── ui/            # Podstawowe komponenty UI
│   │       ├── Button.tsx
│   │       ├── Card.tsx
│   │       ├── Input.tsx
│   │       └── ...
│   │
│   └── molecules/         # Złożone komponenty
│       ├── Navbar.tsx
│       ├── Footer.tsx
│       ├── GodCard.tsx
│       ├── GodsPanel.tsx
│       ├── LoRaTrainingPanel.tsx
│       ├── TechStackGrid.tsx
│       ├── ContactForm.tsx
│       ├── PricingCalculator.tsx
│       ├── GodAwakeningProgress.tsx
│       └── ChatWidget.tsx
│
└── app/globals.css        # Style globalne z CSS Variables
```

---

## 🎨 Atomic Design

### Atoms (lib/atoms/)

Najprostsze, niepodzielne komponenty. Nie zawierają logiki biznesowej.

**Przykłady:**

- `GradientText` - tekst z gradientem
- `Reveal` - animacja pojawiania się
- `Section` - wrapper sekcji z paddingiem
- `ThemeToggle` - przełącznik dark/light mode
- `ui/Button` - bazowy przycisk
- `ui/Card` - bazowa karta

**Kiedy używać:**

- Pojedyncze elementy UI
- Brak zależności od innych komponentów
- Możliwość wielokrotnego użycia

### Molecules (lib/molecules/)

Bardziej złożone komponenty złożone z atomów i logiki.

**Przykłady:**

- `Navbar` - nawigacja (używa `ThemeToggle`)
- `Footer` - stopka
- `GodCard` - karta boga (używa `Card`, `Button`)
- `GodsPanel` - panel z bogami (używa `GodCard`)
- `ContactForm` - formularz kontaktowy (używa `Input`, `Textarea`, `Button`)

**Kiedy używać:**

- Komponenty z logiką
- Komponenty łączące atomy
- Sekcje strony

### Pages (pages/)

Komponenty całych stron, które łączą molecules i atoms.

**Struktura:**

```tsx
// pages/HomePage.tsx
import Section from "@atoms/Section";
import { GodsPanel } from "@molecules/GodsPanel";

export default function HomePage() {
  return (
    <>
      <Section>{/* ... */}</Section>
      <GodsPanel />
    </>
  );
}
```

**Routing:**

```tsx
// app/page.tsx (tylko routing i metadata)
export const metadata = { title: "Home" };
export { default } from "@pages/HomePage";
```

---

## 📦 Aliasy Importów

Zdefiniowane w `tsconfig.json`:

```typescript
{
  "paths": {
    "@/*": ["./*"],                    // Ogólny alias
    "@atoms/*": ["./lib/atoms/*"],     // Atomy
    "@molecules/*": ["./lib/molecules/*"], // Molecules
    "@pages/*": ["./pages/*"],         // Strony
    "@web/*": ["./*"]                  // Legacy (do usunięcia)
  }
}
```

### Przykłady użycia:

```tsx
// ✅ Dobre
import GradientText from "@atoms/GradientText";
import { Navbar } from "@molecules/Navbar";
import HomePage from "@pages/HomePage";
import { Card } from "@atoms/ui/Card";

// ❌ Unikaj
import GradientText from "../../../lib/atoms/GradientText";
import { Navbar } from "@web/components/Navbar"; // stary alias
```

---

## 🔄 Migracja z Starej Struktury

### Przed:

```
components/
├── GradientText.tsx
├── Navbar.tsx
├── Footer.tsx
└── ui/
    └── Card.tsx

app/
├── page.tsx (150 linii kodu)
├── about/
│   └── page.tsx (100 linii kodu)
```

### Po:

```
lib/
├── atoms/
│   ├── GradientText.tsx
│   └── ui/
│       └── Card.tsx
└── molecules/
    ├── Navbar.tsx
    └── Footer.tsx

pages/
├── HomePage.tsx (150 linii kodu)
└── AboutPage.tsx (100 linii kodu)

app/
├── page.tsx (1 linia: export { default } from '@pages/HomePage')
└── about/
    └── page.tsx (3 linie: metadata + export)
```

---

## 💡 Best Practices

### 1. Separacja Odpowiedzialności

**app/\*** - tylko routing i metadata\*\*

```tsx
export const metadata = { title: "O nas" };
export { default } from "@pages/AboutPage";
```

**pages/** - logika strony\*\*

```tsx
export default function AboutPage() {
  // Tutaj cała logika strony
  return <Section>...</Section>;
}
```

### 2. Importy

Zawsze używaj aliasów:

```tsx
// ✅ Dobrze
import Section from "@atoms/Section";
import { Navbar } from "@molecules/Navbar";

// ❌ Źle
import Section from "../../lib/atoms/Section";
```

### 3. Komponenty UI

Podstawowe komponenty UI zawsze w `atoms/ui/`:

```tsx
// atoms/ui/Button.tsx
export function Button({ children, ...props }) {
  return (
    <button className="..." {...props}>
      {children}
    </button>
  );
}
```

### 4. Re-eksport

Używaj re-eksportu dla czytelności:

```tsx
// app/page.tsx
export { default } from "@pages/HomePage";
```

---

## 🚀 Korzyści Nowej Struktury

1. **Czytelność** - jasne rozdzielenie routing vs logika
2. **Atomic Design** - łatwe zarządzanie komponentami
3. **Reużywalność** - łatwe importy z `@atoms` i `@molecules`
4. **Skalowalność** - dodawanie nowych stron to 1 linia w `app/`
5. **Testowanie** - łatwe testowanie komponentów pages/ bez Next.js
6. **Type Safety** - aliasy wspierane przez TypeScript

---

## 📚 Dodatkowe Pliki

- `CSS_VARIABLES_GUIDE.md` - przewodnik po zmiennych CSS
- `STRUCTURE.md` - ten plik
- `tsconfig.json` - konfiguracja aliasów

---

**Autor**: AI Assistant
**Data**: 2025-10-26
**Wersja**: 1.0
