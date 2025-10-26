# CSS Variables Guide - Control Center

Ten plik zawiera przewodnik po wszystkich zmiennych CSS zdefiniowanych w `globals.css`.

## 📚 Spis Treści

1. [Typografia](#typografia)
2. [Kolory Brand](#kolory-brand)
3. [Kolory Pastelowe](#kolory-pastelowe)
4. [Motywy (Light/Dark)](#motywy)
5. [Komponenty](#komponenty)
6. [Gradienty](#gradienty)
7. [Spacing i Sizing](#spacing-i-sizing)
8. [Przejścia i Animacje](#przejścia-i-animacje)
9. [Z-Index](#z-index)

---

## Typografia

Wszystkie czcionki są zaimportowane przez Next.js w `layout.tsx`:

```css
--font-sans: var(--font-inter), var(--font-poppins), ui-sans-serif, system-ui;
--font-display: var(--font-orbitron), var(--font-poppins), ui-sans-serif;
--font-body: var(--font-poppins), ui-sans-serif, system-ui;
```

### Użycie:

```css
.my-heading {
  font-family: var(--font-display);
}

.my-body-text {
  font-family: var(--font-body);
}
```

---

## Kolory Brand

Główne kolory marki:

```css
--brand-primary: #ff00ff; /* Magenta */
--brand-secondary: #00ffff; /* Cyan */
--brand-accent: #ff7a00; /* Orange */
--brand-yellow: #ffff00; /* Yellow */
--brand-green: #00ff00; /* Green */
--brand-red: #ff0000; /* Red */
--brand-blue: #0000ff; /* Blue */
```

### Użycie:

```css
.brand-button {
  background-color: var(--brand-primary);
  color: white;
}

.brand-border {
  border: 2px solid var(--brand-secondary);
}
```

---

## Kolory Pastelowe

Używane głównie w animowanym gradiencie nagłówka:

```css
--pastel-cyan: #a0e7ff;
--pastel-magenta: #ffb0ff;
--pastel-yellow: #ffffb0;
--pastel-orange: #ffc899;
--pastel-red: #ffb0b0;
--pastel-green: #b0ffb0;
--pastel-blue: #b0b0ff;
--pastel-peach: #ffd0a0;
--pastel-cream: #ffffc0;
```

### Użycie:

```css
.soft-highlight {
  background-color: var(--pastel-cyan);
}
```

---

## Motywy

### Tła (Backgrounds)

```css
--bg-primary       /* Główne tło */
--bg-secondary     /* Drugorzędne tło */
--bg-tertiary      /* Trzeciorzędne tło */
--bg-card          /* Tło kart */
--bg-hover         /* Tło przy hover */
```

### Teksty

```css
--text-primary     /* Główny tekst */
--text-secondary   /* Drugorzędny tekst */
--text-tertiary    /* Trzeciorzędny tekst */
--text-muted       /* Wyciszony tekst */
```

### Obramowania

```css
--border           /* Standardowe obramowanie */
--border-hover     /* Obramowanie przy hover */
--border-focus     /* Obramowanie przy focus */
```

### Cienie

```css
--shadow-sm        /* Mały cień */
--shadow-md        /* Średni cień */
--shadow-lg        /* Duży cień */
--shadow-xl        /* Extra duży cień */
```

### Przykład użycia:

```css
.my-card {
  background: var(--bg-card);
  color: var(--text-primary);
  border: 1px solid var(--border);
  box-shadow: var(--shadow-md);
}

.my-card:hover {
  border-color: var(--border-hover);
  box-shadow: var(--shadow-lg);
}
```

**Uwaga**: Te zmienne automatycznie przełączają się między trybem jasnym i ciemnym!

---

## Komponenty

### Header

```css
--header-bg        /* Tło nagłówka */
--header-border    /* Obramowanie nagłówka */
```

### Footer

```css
--footer-bg        /* Tło stopki */
--footer-text      /* Tekst stopki */
```

### Karty

```css
--card-bg              /* Tło karty */
--card-border          /* Obramowanie karty */
--card-shadow          /* Cień karty */
--card-hover-shadow    /* Cień karty przy hover */
```

### Przyciski

```css
--button-primary-bg        /* Tło głównego przycisku */
--button-primary-hover     /* Tło głównego przycisku przy hover */
--button-secondary-bg      /* Tło drugorzędnego przycisku */
--button-secondary-hover   /* Tło drugorzędnego przycisku przy hover */
```

### Inputy

```css
--input-bg               /* Tło pola input */
--input-border           /* Obramowanie pola input */
--input-focus-border     /* Obramowanie pola input przy focus */
```

### Highlighted (Podświetlony tekst)

```css
--highlighted-bg         /* Tło podświetlonego tekstu */
--highlighted-text       /* Kolor podświetlonego tekstu */
```

### Przykład użycia:

```css
header {
  background: var(--header-bg);
  border-bottom: 1px solid var(--header-border);
}

.button-primary {
  background: var(--button-primary-bg);
}

.button-primary:hover {
  background: var(--button-primary-hover);
}

mark {
  background: var(--highlighted-bg);
  color: var(--highlighted-text);
}
```

---

## Gradienty

```css
--brand-grad-start     /* Początek gradientu brand */
--brand-grad-end       /* Koniec gradientu brand */
--gradient-brand       /* Gotowy gradient brand */
--gradient-logo        /* Gotowy gradient logo */
```

### Użycie:

```css
.gradient-button {
  background: var(--gradient-brand);
}

.logo-text {
  background: var(--gradient-logo);
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
```

---

## Spacing i Sizing

### Border Radius

```css
--radius           /* 0.5rem - standardowy */
--radius-sm        /* 0.25rem - mały */
--radius-md        /* 0.375rem - średni */
--radius-lg        /* 0.75rem - duży */
--radius-xl        /* 1rem - extra duży */
--radius-full      /* 9999px - pełne koło */
```

### Spacing

```css
--spacing-xs       /* 0.25rem */
--spacing-sm       /* 0.5rem */
--spacing-md       /* 1rem */
--spacing-lg       /* 1.5rem */
--spacing-xl       /* 2rem */
--spacing-2xl      /* 3rem */
```

### Przykład użycia:

```css
.rounded-card {
  border-radius: var(--radius-lg);
  padding: var(--spacing-lg);
  margin-bottom: var(--spacing-xl);
}

.circle-button {
  border-radius: var(--radius-full);
  padding: var(--spacing-md);
}
```

---

## Przejścia i Animacje

```css
--transition-fast      /* 150ms ease */
--transition-base      /* 200ms ease */
--transition-slow      /* 300ms ease */
--transition-slower    /* 500ms ease */
```

### Przykład użycia:

```css
.smooth-button {
  transition: all var(--transition-base);
}

.slow-fade {
  transition: opacity var(--transition-slower);
}
```

---

## Z-Index

```css
--z-dropdown          /* 1000 */
--z-sticky            /* 1020 */
--z-fixed             /* 1030 */
--z-modal-backdrop    /* 1040 */
--z-modal             /* 1050 */
--z-popover           /* 1060 */
--z-tooltip           /* 1070 */
```

### Przykład użycia:

```css
.navbar {
  position: sticky;
  z-index: var(--z-sticky);
}

.modal {
  z-index: var(--z-modal);
}

.tooltip {
  z-index: var(--z-tooltip);
}
```

---

## Jak zmienić kolor globalnie?

### Przykład: Zmiana głównego koloru brand

W `globals.css`, w sekcji `:root`, zmień:

```css
--brand-primary: #ff00ff; /* Zmień na swój kolor */
```

To automatycznie zaktualizuje:

- Przyciski używające `--button-primary-bg`
- Gradienty używające `--brand-grad-start`
- Podświetlony tekst używający `--highlighted-text`
- I wszystko inne co używa tej zmiennej!

### Przykład: Zmiana tła kart tylko w dark mode

W `globals.css`, w sekcji `.dark`, zmień:

```css
--bg-card: #1a1f2e; /* Twój nowy kolor */
```

---

## Klasy pomocnicze

Klasy już zdefiniowane w `globals.css`:

### `.gradient-animated-text`

Animowany gradient w kolorach pastelowych (używany w głównym nagłówku)

### `.gradient-logo-text`

Statyczny gradient w kolorach logo (pomarańczowy → magenta → cyan)

### `.glass`

Efekt szkła (glassmorphism)

### `.fade-down-slow`

Animacja pojawiania się z góry (wolna)

---

## Tips & Tricks

1. **Zawsze używaj zmiennych CSS zamiast hardkodowanych kolorów**

   ```css
   /* ❌ Źle */
   background: #000000;

   /* ✅ Dobrze */
   background: var(--bg-primary);
   ```

2. **Chcesz dodać nową zmienną?**

   - Dodaj ją w sekcji `:root` dla light mode
   - Jeśli ma się różnić w dark mode, dodaj też w sekcji `.dark`

3. **Testowanie kolorów:**

   - Zmień wartość zmiennej w DevTools (Chrome/Firefox)
   - Zobaczysz zmiany na żywo
   - Gdy Ci pasuje, zapisz w `globals.css`

4. **Semantic naming:**
   - Używaj `--bg-*` dla tła
   - Używaj `--text-*` dla tekstu
   - Używaj `--border-*` dla obramowań
   - To ułatwia utrzymanie kodu!

---

**Autor**: AI Assistant
**Data**: 2025-10-26
**Wersja**: 1.0
