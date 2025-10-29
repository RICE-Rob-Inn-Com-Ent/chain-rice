# Next.js Hydration Errors - Quick Fix Guide

## 🐛 Problem

```
Error: Hydration failed because the initial UI does not match 
what was rendered on the server.
```

### Co to znaczy?

**Hydration** = Next.js renderuje HTML na serwerze (SSR), potem React "hydratuje" go na kliencie. Jeśli HTML się nie zgadza → błąd!

---

## 🔍 Przyczyny

### 1. ✅ **Fetch w useEffect** (NAJCZĘSTSZY!)

```tsx
// ❌ ŹLE - powoduje hydration error
export default function MyComponent() {
  const [data, setData] = useState([]);
  
  useEffect(() => {
    fetch('/api/data').then(res => setData(res.json()));
  }, []);
  
  return <div>{data.map(...)}</div>; // Server: puste, Client: pełne
}
```

**Dlaczego?**
- Server: `useEffect` NIE działa → `data = []` → puste DOM
- Client: `useEffect` działa → `data = [...]` → pełne DOM
- HTML się nie zgadza → BŁĄD!

### 2. Browser API (`window`, `document`, `localStorage`)

```tsx
// ❌ ŹLE
const MyComponent = () => {
  const width = window.innerWidth; // Server nie ma 'window'!
  return <div>{width}</div>;
};
```

### 3. Losowe wartości / Date.now()

```tsx
// ❌ ŹLE
const MyComponent = () => {
  const id = Math.random(); // Server: 0.123, Client: 0.456
  return <div>{id}</div>;
};
```

### 4. Warunkowe renderowanie oparte o state

```tsx
// ❌ ŹLE
const MyComponent = () => {
  const [mounted, setMounted] = useState(false);
  
  useEffect(() => setMounted(true), []);
  
  if (!mounted) return null; // Server: null, Client: <nav>
  return <nav>...</nav>;
};
```

---

## ✅ Rozwiązania

### Rozwiązanie 1: Dynamic Import z `ssr: false` (ZALECANE!)

```tsx
// app/page.tsx
"use client";

import dynamic from "next/dynamic";

// Wyłącz SSR dla komponentu
const MyComponent = dynamic(() => import("./MyComponent"), { 
  ssr: false // ← Renderuj TYLKO na kliencie
});

export default function Page() {
  return <MyComponent />;
}
```

**Kiedy użyć:**
- Komponent używa `fetch` w `useEffect`
- Komponent używa browser API (`window`, `localStorage`)
- Komponent ma warunkowe renderowanie

**Bonus - Loading state:**

```tsx
const MyComponent = dynamic(() => import("./MyComponent"), {
  ssr: false,
  loading: () => <div>Loading...</div> // Pokaż podczas ładowania
});
```

---

### Rozwiązanie 2: `useEffect` + `mounted` state

```tsx
"use client";

import { useState, useEffect } from "react";

export default function MyComponent() {
  const [mounted, setMounted] = useState(false);
  const [data, setData] = useState([]);

  useEffect(() => {
    setMounted(true);
    fetch('/api/data').then(res => setData(res.json()));
  }, []);

  // Podczas SSR nie renderuj nic
  if (!mounted) {
    return <div>Loading...</div>; // Ten sam HTML na server i client!
  }

  return <div>{data.map(...)}</div>;
}
```

**Jak to działa:**
- Server: `mounted = false` → `<div>Loading...</div>`
- Client (pierwszy render): `mounted = false` → `<div>Loading...</div>` (MATCH! ✓)
- Client (useEffect): `mounted = true` → pełne dane

---

### Rozwiązanie 3: Server Components + Client Components

```tsx
// app/page.tsx (Server Component - domyślnie)
import ClientComponent from "./ClientComponent";

export default async function Page() {
  // Fetch na serwerze
  const data = await fetch('http://api.com/data').then(r => r.json());
  
  return <ClientComponent data={data} />;
}

// ClientComponent.tsx
"use client";

export default function ClientComponent({ data }) {
  return <div>{data.map(...)}</div>;
}
```

**Zalety:**
- Data fetching na serwerze (szybszy SEO)
- Nie ma hydration mismatch
- Client component dostaje gotowe dane

---

### Rozwiązanie 4: `typeof window !== "undefined"`

```tsx
export default function MyComponent() {
  // Sprawdź czy jesteś na kliencie
  const isClient = typeof window !== "undefined";
  
  if (!isClient) {
    return <div>Loading...</div>; // SSR
  }
  
  // Bezpieczne użycie window
  const width = window.innerWidth;
  return <div>{width}</div>;
}
```

---

## 🎯 Decyzja Tree - Które rozwiązanie?

```
Masz hydration error?
│
├─ Component używa fetch/useState/useEffect?
│  └─ ✅ Dynamic import z ssr: false (Rozwiązanie 1)
│
├─ Potrzebujesz SEO dla tego contentu?
│  └─ ✅ Server Component + props (Rozwiązanie 3)
│
├─ Używasz window/localStorage?
│  └─ ✅ typeof window check (Rozwiązanie 4)
│
└─ Prosty case bez SEO?
   └─ ✅ useEffect + mounted state (Rozwiązanie 2)
```

---

## 🔧 Jak Naprawiono Ten Projekt

### Problem 1: Pages z fetch w useEffect

**Przed:**
```tsx
// page.tsx
"use client";

import HomePage from "./pages/Home";

export default function Page() {
  return <HomePage />; // HomePage ma fetch w useEffect → BŁĄD!
}
```

**Po (próba #1):**
```tsx
"use client";

import dynamic from "next/dynamic";
import { Header } from "@rice-mono/ui-kit/lib";

const HomePage = dynamic(() => import("./pages/Home"), { ssr: false });

export default function Page() {
  return (
    <Header>
      <HomePage />
    </Header>
  );
}
```

**Błąd nadal występował!** 

### Problem 2: Normal import + Dynamic children = Mismatch

Header był importowany NORMALNIE, ale children były DYNAMIC.

- Server renderował: `<Header><PageLoader /></Header>`
- Client renderował: `<Header><HomePage full /></Header>`
- Mismatch! ❌

**Rozwiązanie finalne:**
```tsx
"use client";

import dynamic from "next/dynamic";

const HomePage = dynamic(() => import("./pages/Home"), { ssr: false });

export default function Page() {
  return (
    <div className="flex min-h-screen flex-col">
      <main className="flex-1">
        <HomePage />
      </main>
    </div>
  );
}
```

**Kluczowe:**
- ❌ Nie mieszaj normal imports z dynamic children
- ✅ Albo wszystko dynamic, albo wszystko normal
- ✅ Wrapper HTML może być inline (statyczny)

**Pliki zmienione:**
- `.project/web/app/page.tsx` ✓

---

## 🐛 Debugging Tips

### 1. Sprawdź console

```
Warning: Text content did not match. Server: "false" Client: "true"
```

To podpowie gdzie jest mismatch!

### 2. Użyj `suppressHydrationWarning`

```tsx
<div suppressHydrationWarning>
  {new Date().toISOString()} {/* Różne na server/client */}
</div>
```

**UWAGA:** To ukrywa warning, nie naprawia problemu! Użyj tylko gdy wiesz co robisz.

### 3. Sprawdź który komponent

```tsx
// Dodaj console.log
useEffect(() => {
  console.log("Component mounted on client");
}, []);

console.log("Component rendered (server + client)");
```

### 4. Wyłącz SSR dla całej strony (ostateczność)

```tsx
// next.config.mjs
export default {
  experimental: {
    serverComponents: false // ❌ Nie zalecane!
  }
}
```

---

## 📊 Performance Impact

| Rozwiązanie | SEO | Performance | Hydration | Use Case |
|-------------|-----|-------------|-----------|----------|
| `ssr: false` | ❌ Brak | ⚡ Szybki | ✅ Brak błędu | Admin panele, dashboardy |
| Server Component | ✅ Pełny | ⚡⚡ Najszybszy | ✅ Brak błędu | Landing pages, marketing |
| `useEffect + mounted` | ❌ Brak | ⚠️ Wolniejszy | ✅ Brak błędu | Proste komponenty |
| `suppressHydrationWarning` | ✅ Częściowy | ⚡ Szybki | ⚠️ Ukrywa błąd | Timestamps, unikalne ID |

---

## 🎊 Best Practices

### ✅ DO:

1. Używaj Server Components dla statycznych danych
2. Używaj `dynamic` z `ssr: false` dla admin paneli
3. Dodawaj loading states
4. Fetchuj dane na serwerze gdy możesz

### ❌ DON'T:

1. Nie używaj `window` bez `typeof window` check
2. Nie używaj `Math.random()` w render
3. Nie fetchuj w `useEffect` jeśli potrzebujesz SEO
4. Nie używaj `suppressHydrationWarning` bez powodu

---

## 🔗 Przydatne Linki

- [Next.js Docs - Hydration Error](https://nextjs.org/docs/messages/react-hydration-error)
- [Next.js Docs - Dynamic Import](https://nextjs.org/docs/app/building-your-application/optimizing/lazy-loading)
- [React Docs - useEffect](https://react.dev/reference/react/useEffect)

---

## 🚀 Quick Checklist

Przed deploymentem sprawdź:

- [ ] Wszystkie komponenty z `fetch` mają `ssr: false` lub są Server Components
- [ ] Nie używasz `window` bez sprawdzenia
- [ ] Nie używasz losowych wartości w render
- [ ] Loading states są zdefiniowane
- [ ] `console.log` usunięte
- [ ] Testowane w trybie production (`yarn build && yarn start`)

---

**Hydration errors solved! 🎉**

