# Co Powinieneś Zobaczyć Po Restarcie

## 🔄 Po restarcie dev servera (port 3001)

### 1. Sidebar Navigation - ZMIENIONE ✨

**Przed:**

```
- Dashboard
- Models
- LoRA Training
- Prices          ← USUNIĘTE
- Components
```

**Teraz:**

```
- Dashboard
- Models
- GiPT-1 Training  ← NOWE! 🆕
- LoRA Training
- Components
```

---

### 2. Nowa Strona: GiPT-1 Training ✨

Po kliknięciu "GiPT-1 Training" zobaczysz:

**Layout (3 kolumny):**

```
┌─────────────────────────────────────────────────────────────────┐
│                     GiPT-1 TRAINING PAGE                        │
├──────────────┬──────────────────────┬───────────────────────────┤
│              │                      │                           │
│ LEFT COLUMN  │   MIDDLE COLUMN      │   RIGHT COLUMN            │
│              │                      │                           │
│ ┌──────────┐ │ ┌─────────────────┐  │ ┌──────────────────────┐ │
│ │ Model    │ │ │ Dataset Upload  │  │ │ Progress Tracking    │ │
│ │ Selection│ │ │                 │  │ │                      │ │
│ │          │ │ │ • Text (JSON)   │  │ │ • LLM Progress: 0%   │ │
│ │ ☑️ Thoth  │ │ │ • Images (ZIP)  │  │ │ • SD Progress: 0%    │ │
│ │ ☑️ Ra     │ │ │                 │  │ │                      │ │
│ │ ☐ Isis   │ │ └─────────────────┘  │ └──────────────────────┘ │
│ │ ☐ Bastet │ │                      │                           │
│ │ ☐ Maat   │ │ ┌─────────────────┐  │ ┌──────────────────────┐ │
│ │ ☐ Khnum  │ │ │ LoRA Config     │  │ │ Model Preview        │ │
│ │          │ │ │                 │  │ │                      │ │
│ │ VRAM:    │ │ │ • Rank: 16      │  │ │ 🧬 GiPT-1            │ │
│ │ 7.6 GB   │ │ │ • Alpha: 32     │  │ │ 2 models combined    │ │
│ └──────────┘ │ │ • LR: 0.0002    │  │ │                      │ │
│              │ │                 │  │ │ • Thoth (Text)       │ │
│ ┌──────────┐ │ └─────────────────┘  │ │ • Ra (Images)        │ │
│ │ Training │ │                      │ └──────────────────────┘ │
│ │ Mode     │ │ ┌─────────────────┐  │                           │
│ │          │ │ │ [START TRAINING]│  │                           │
│ │ • Hybrid │ │ └─────────────────┘  │                           │
│ └──────────┘ │                      │                           │
└──────────────┴──────────────────────┴───────────────────────────┘
```

**Funkcje:**

✅ **Model Selection**: Checkboxy dla 6 gods ✅ **VRAM Calculator**: Automatyczne liczenie zajętej pamięci ✅ **Training
Modes**: Sequential, Parallel, Hybrid ✅ **Dataset Upload**: JSON dla tekstu, ZIP dla obrazów ✅ **LoRA Config**:
Sliders dla rank, alpha, learning rate, epochs, batch size ✅ **Start Button**: "Start GiPT-1 Training" (gradient
purple→pink) ✅ **Progress Bars**: Osobne dla LLM i SD ✅ **Model Preview**: Podgląd wybranego zestawu modeli

---

### 3. Styl Wizualny

**Kolory:**

- Gradient fioletowo-różowy (matching dashboard)
- Ciemny tło (matching całej aplikacji)
- Zielone checkmarki przy wybranych modelach
- Purple button dla "Start Training"

**Animacje:**

- Hover effects na kartach modeli
- Progress bars z animacją
- Loading spinner podczas treningu

---

## 🆕 Port 3002 - Marketing Site

Jeśli uruchomisz `yarn dev` z roota, zobaczysz też:

**http://localhost:3002**

```
┌─────────────────────────────────────────────────────────────────┐
│  Logo: 🧬 Rice AI        [Home] [Pricing] [About] [Demo] ...   │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│                    ONE MODEL, SIX SUPERPOWERS                   │
│                                                                 │
│     GiPT-1 combines text, vision, code, audio, and image       │
│           generation in a single unified AI model.             │
│                                                                 │
│              [Try Live Demo →]    [View Pricing]               │
│                                                                 │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐      │
│  │ 📚 Thoth │  │ ☀️ Ra    │  │ ✨ Isis  │  │ 🐱 Bastet│      │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘      │
│  ┌──────────┐  ┌──────────┐                                   │
│  │ ⚖️ Maat  │  │ 🏺 Khnum │                                   │
│  └──────────┘  └──────────┘                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

5 stron:

- `/` - Landing page
- `/pricing` - Plany ($49, $199, Custom)
- `/about` - O GiPT-1
- `/demo` - Interaktywne demo
- `/contact` - Formularz kontaktowy

---

## ✅ Checklist Po Restarcie

Sprawdź czy widzisz:

**Admin Panel (3001):**

- [ ] Sidebar ma "GiPT-1 Training" zamiast "Prices"
- [ ] Kliknięcie otwiera nową stronę
- [ ] Widoczne checkboxy dla 6 gods
- [ ] VRAM calculator działa
- [ ] Można wybierać training mode
- [ ] "Start Training" button widoczny

**Marketing Site (3002) - jeśli uruchomione:**

- [ ] Landing page się ładuje
- [ ] 6 kart z gods
- [ ] Navigation działa
- [ ] Można przejść do /pricing
- [ ] Demo interface na /demo

---

## 🐛 Jeśli Nadal Nie Widzisz Zmian:

1. **Sprawdź czy plik istnieje:**

   ```bash
   ls -la /home/mrDinkelman/rice-mono/.frontend/web/app/GiPT1Training.tsx
   ```

   Powinien być ~700 linii

2. **Sprawdź Layout.tsx:**

   ```bash
   grep "gipt1-training" /home/mrDinkelman/rice-mono/.frontend/web/app/Layout.tsx
   ```

   Powinien zwrócić linię z "GiPT-1 Training"

3. **Sprawdź App.tsx:**

   ```bash
   grep "GiPT1Training" /home/mrDinkelman/rice-mono/.frontend/web/app/App.tsx
   ```

   Powinien zwrócić import i case dla "gipt1-training"

4. **Sprawdź błędy w konsoli:**
   - Otwórz DevTools (F12)
   - Zobacz czy są czerwone błędy
   - Może brakować importu?

5. **Restart na świeżo:**
   ```bash
   cd /home/mrDinkelman/rice-mono/.frontend/web
   rm -rf node_modules/.vite  # Wyczyść Vite cache
   yarn dev
   ```

---

## 📸 Screenshot Co Powinieneś Zobaczyć

Po kliknięciu "GiPT-1 Training" w sidebar:

```
╔══════════════════════════════════════════════════════════════════╗
║  🧬 GiPT-1 Multimodal Training                                  ║
║  Combine multiple AI gods into one unified model                ║
╠══════════════════════════════════════════════════════════════════╣
║                                                                  ║
║  ℹ️ What is GiPT-1?                                             ║
║  GiPT-1 (General intelligence Pantheon Transformer) is a        ║
║  unified model combining all 6 Egyptian AI gods...              ║
║                                                                  ║
╠══════════════════════════════════════════════════════════════════╣
║  [3 COLUMN LAYOUT WITH MODEL SELECTION + CONFIG + PROGRESS]     ║
╚══════════════════════════════════════════════════════════════════╝
```

**Jeśli to widzisz = SUCCESS! ✅**

---

🎯 **Wszystko gotowe - ciesz się nowym interfejsem do trenowania GiPT-1!**
