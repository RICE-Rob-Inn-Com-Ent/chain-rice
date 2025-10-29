# ⚡ Hydration Error - Quick Fix Card

## 🚨 Błąd: "Expected server HTML to contain a matching..."

### ✅ NAJCZĘSTSZY CASE: Dynamic children + Normal parent

```tsx
// ❌ ŹLE - powoduje hydration error
import { Header } from "@rice-mono/ui-kit";
const HomePage = dynamic(() => import("./pages/Home"), { ssr: false });

export default function Page() {
  return (
    <Header>           {/* ← Normal import (renderuje na server + client) */}
      <HomePage />     {/* ← Dynamic (renderuje tylko na client) */}
    </Header>          {/* MISMATCH! */}
  );
}
```

**Dlaczego nie działa:**
- Server: `<Header><div>Loading...</div></Header>` (bo HomePage jest dynamic)
- Client: `<Header><HomePage full content /></Header>` (HomePage się załadował)
- HTML się nie zgadza → ERROR!

### ✅ ROZWIĄZANIE: Inline wrapper zamiast imported component

```tsx
// ✅ DOBRZE
const HomePage = dynamic(() => import("./pages/Home"), { ssr: false });

export default function Page() {
  return (
    <div className="wrapper">    {/* ← Inline HTML (zawsze taki sam) */}
      <main>
        <HomePage />             {/* ← Dynamic (renderuje tylko na client) */}
      </main>
    </div>                       {/* ✓ Brak mismatch! */}
  );
}
```

---

## 📋 Quick Checklist

Przed deploymentem sprawdź:

- [ ] Czy wszystkie komponenty z `fetch/useEffect` mają `ssr: false`?
- [ ] Czy NIE mieszasz normal imports z dynamic children?
- [ ] Czy używasz inline HTML dla wrapperów zamiast imported components?
- [ ] Czy testowałeś w przeglądarce z czystym cache?

---

## 🔧 Szablon - Copy & Paste

```tsx
"use client";

import dynamic from "next/dynamic";

// Loading state
const PageLoader = () => (
  <div className="flex items-center justify-center min-h-screen">
    <div>Loading...</div>
  </div>
);

// Dynamic imports (ssr: false dla komponentów z fetch/browser API)
const MyPage = dynamic(() => import("./pages/MyPage"), { 
  ssr: false,
  loading: () => <PageLoader />
});

export default function Page() {
  return (
    <div className="wrapper">     {/* Inline wrapper - nie imported component! */}
      <main>
        <MyPage />
      </main>
    </div>
  );
}
```

---

## 🎯 Szybka Diagnoza

```
Hydration error?
│
├─ Masz imported Header/Layout?
│  └─ Zastąp inline <div> + <main>
│
├─ Masz dynamic children?
│  └─ Upewnij się że parent też jest dynamic LUB inline HTML
│
└─ Masz fetch w useEffect?
   └─ Użyj dynamic import z ssr: false
```

---

## 🚀 Test po naprawie

1. Zrestartuj dev server (opcjonalnie)
2. Otwórz http://localhost:3002
3. Ctrl+Shift+R (hard reload)
4. Sprawdź console - nie powinno być błędów!

---

**To nie magia, to React SSR/CSR sync! 🎯**

