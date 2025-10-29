# Port Separation - Admin vs Marketing

## 🎯 Architektura Dual-Site

### Port 3001 - Admin Panel (Vite)
**Lokalizacja:** `.frontend/web/`
**Dla kogo:** Wewnętrzny zespół, power users, administratorzy
**Technologia:** Vite + React

#### Komponenty:
- ✅ **Dashboard** - przegląd systemu
- ✅ **Models** - zarządzanie modelami AI
- ✅ **GiPT-1 Training** - interfejs trenowania multimodal model
- ✅ **LoRA Training** - fine-tuning modeli
- ✅ **Components** - showcase komponentów UI
- ✅ **GodsPanel** - status bogów (Ollama models)
- ✅ **LoRaTrainingPanel** - interfejs trenowania LoRA

#### Charakterystyka:
- Backend API calls (God Manager, Ollama, Ra)
- Złożone interfejsy administratorskie
- Real-time updates
- VRAM monitoring
- Model management

---

### Port 3002 - Marketing Site (Next.js)
**Lokalizacja:** `.project/web/`
**Dla kogo:** Potencjalni klienci, SEO, public
**Technologia:** Next.js + React

#### Strony:
- ✅ **Home** - landing page z hero section
- ✅ **About** - o firmie
- ✅ **Services** - usługi
- ✅ **Pricing** - cennik
- ✅ **Contact** - kontakt

#### Charakterystyka:
- **BEZ** GodsPanel
- **BEZ** LoRaTrainingPanel
- **BEZ** backend API calls
- Czysty marketing content
- SEO-optimized
- Statyczny content (lub ISR/SSG)

---

## 📊 Porównanie

| Feature | Port 3001 (Admin) | Port 3002 (Marketing) |
|---------|-------------------|----------------------|
| GodsPanel | ✅ YES | ❌ NO |
| LoRaTrainingPanel | ✅ YES | ❌ NO |
| GiPT-1 Training | ✅ YES | ❌ NO |
| Backend API calls | ✅ YES | ❌ NO |
| Marketing content | ❌ NO | ✅ YES |
| SEO optimization | ❌ NO | ✅ YES |
| Public access | ❌ NO | ✅ YES |
| Authentication | Future: YES | ❌ NO |
| VRAM monitoring | ✅ YES | ❌ NO |

---

## 🚫 Co NIE powinno być na Marketing Site (3002)

### ❌ Admin Components:
- `GodsPanel` - to admin tool
- `LoRaTrainingPanel` - to admin tool
- `GiPT1Training` - to admin tool
- Wszystkie komponenty zarządzające modelami

### ❌ Technical Details:
- Lazy Loading (VRAM)
- LoRa adapters
- Protocol Buffers
- Bazel build system
- Ollama API references

### ❌ Backend Dependencies:
- God Manager API calls
- Ollama API calls
- Ra (Stable Diffusion) API calls
- Real-time model status

---

## ✅ Co POWINNO być na Marketing Site (3002)

### ✅ Marketing Content:
- Hero sections z value proposition
- Feature highlights (business benefits)
- Service descriptions
- Pricing plans
- Contact forms
- Testimonials (future)
- Case studies (future)

### ✅ Business Focus:
- **AI & Machine Learning** - jak pomagamy w biznesie
- **Web & Mobile Development** - nasze usługi
- **Cloud & DevOps** - infrastruktura
- **Automatyzacja** - oszczędność czasu

### ✅ Components:
- `GradientText` - styling
- `Reveal` - animations
- `Section` - layout
- `Button` - CTA
- `Card` - content boxes

---

## 🔧 Jak Utrzymać Separację

### 1. Import Rules

```tsx
// ❌ BAD - w marketing site
import { GodsPanel, LoRaTrainingPanel } from "@rice-mono/ui-kit/lib";

// ✅ GOOD - w marketing site
import { GradientText, Reveal, Section, Button, Card } from "@rice-mono/ui-kit/lib";
```

### 2. Content Rules

**Admin (3001):**
- Technical jargon OK
- Model names OK (Thoth, Ra, etc.)
- VRAM, GPU references OK
- Complex UI OK

**Marketing (3002):**
- Simple language
- Business benefits
- "AI", "Machine Learning" instead of "LLM", "Ollama"
- Clean, minimal UI

### 3. API Calls

**Admin (3001):**
```typescript
// OK to call backend
fetch('http://localhost:8100/gods')
fetch('http://localhost:8001/ollama/api/generate')
```

**Marketing (3002):**
```typescript
// Only simple form submissions
fetch('/api/contact', { method: 'POST', body: formData })
// No model management calls!
```

---

## 🎯 Decision Tree

```
Mam nowy feature - gdzie go dodać?

├─ Czy wymaga backend API?
│  └─ YES → 3001 (Admin)
│
├─ Czy to zarządzanie modelami/systemem?
│  └─ YES → 3001 (Admin)
│
├─ Czy to content dla klientów?
│  └─ YES → 3002 (Marketing)
│
└─ Czy ma pokazywać technical details?
   ├─ YES → 3001 (Admin)
   └─ NO → 3002 (Marketing)
```

---

## 📝 Checklist dla Nowych Features

### Dodajesz do 3001 (Admin)?
- [ ] Komponent używa backend API
- [ ] Wymaga authentication (future)
- [ ] Pokazuje technical details
- [ ] Zarządza systemem/modelami
- [ ] Jest dla internal users

### Dodajesz do 3002 (Marketing)?
- [ ] Pure React (bez backend calls)
- [ ] SEO-friendly content
- [ ] Business-focused messaging
- [ ] Public-facing
- [ ] Simple, clean UI

---

## 🔍 Troubleshooting

### Problem: NetworkError w marketing site
**Przyczyna:** Próbujesz używać GodsPanel/LoRaTrainingPanel
**Rozwiązanie:** Usuń te komponenty - to admin stuff!

### Problem: Hydration error
**Przyczyna:** Mieszasz SSR (Next.js) z dynamic imports
**Rozwiązanie:** Zobacz `HYDRATION_ERRORS_FIX.md`

### Problem: Content duplicated
**Przyczyna:** Ten sam content na 3001 i 3002
**Rozwiązanie:** Admin = technical, Marketing = business-focused

---

## 🎊 Best Practices

### ✅ DO:
- Trzymaj admin features na 3001
- Trzymaj marketing content na 3002
- Używaj shared UI Kit dla base components
- Testuj oba porty regularnie

### ❌ DON'T:
- Nie mieszaj admin i marketing content
- Nie dodawaj backend calls do marketing site
- Nie duplikuj features między portami
- Nie używaj technical jargon w marketing

---

## 📚 Powiązane Dokumenty

- `HYDRATION_ERRORS_FIX.md` - jak naprawić SSR issues
- `DUAL_SITE_ARCHITECTURE.md` - architektura overview
- `START_DUAL_SITE.md` - jak uruchomić oba serwery

---

**Remember: Admin = Power, Marketing = Simplicity** 🎯

