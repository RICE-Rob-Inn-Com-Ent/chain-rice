# 📦 Third-Party Licenses & Dependencies

> Lista zewnętrznych pakietów, zasobów i narzędzi wykorzystanych w projekcie Meowtopia (Web, Mobile, Backend, Blockchain, AI).

---

## 📱 Frontend / Mobile App (React, Vite, Swift, Kotlin)

| Nazwa pakietu | Wersja  | Licencja | Źródło                                     | Użycie            |
| ------------- | ------- | -------- | ------------------------------------------ | ----------------- |
| React         | 18.x    | MIT      | https://react.dev/                         | UI framework      |
| Vite          | 5.x     | MIT      | https://vitejs.dev/                        | Build system      |
| Tailwind CSS  | 3.x     | MIT      | https://tailwindcss.com                    | UI styling        |
| Lucide Icons  | 0.x     | ISC      | https://lucide.dev                         | Ikony             |
| React Router  | 6.x     | MIT      | https://reactrouter.com                    | Routing           |
| Expo (Kotlin) | N/A     | MIT      | https://expo.dev                           | Aplikacja mobilna |
| SwiftUI       | iOS SDK | Apple    | https://developer.apple.com/xcode/swiftui/ | Aplikacja iOS     |

---

## ⚙️ Backend / API (Python, Django, FastAPI)

| Nazwa pakietu | Wersja | Licencja | Źródło                       | Użycie            |
| ------------- | ------ | -------- | ---------------------------- | ----------------- |
| API           |
| FastAPI       | 0.110  | MIT      | https://fastapi.tiangolo.com | Async API         |
| Uvicorn       | 0.30.x | BSD      | https://www.uvicorn.org      | ASGI server       |
| SQLAlchemy    | 2.x    | MIT      | https://www.sqlalchemy.org   | ORM               |
| psycopg2      | 2.x    | LGPL     | https://www.psycopg.org      | PostgreSQL driver |

---

## 🔐 Blockchain / Token (Go, Rust, Cosmos SDK)

| Nazwa             | Wersja | Licencja     | Źródło                                   | Użycie          |
| ----------------- | ------ | ------------ | ---------------------------------------- | --------------- |
| Cosmos SDK        | 0.50.x | Apache 2.0   | https://github.com/cosmos/cosmos-sdk     | Blockchain      |
| Tendermint        | 0.x    | Apache 2.0   | https://github.com/tendermint/tendermint | Konsensus       |
| Wasmer / CosmWasm | N/A    | MIT / Apache | https://github.com/CosmWasm              | Smart contracts |

---

## 🤖 AI / LLM Integracje

| Nazwa                | Wersja | Licencja   | Źródło                                          | Użycie         |
| -------------------- | ------ | ---------- | ----------------------------------------------- | -------------- |
| LangChain            | 0.x    | MIT        | https://github.com/langchain-ai/langchain       | Integracja LLM |
| OpenAI API           | N/A    | Komercyjna | https://openai.com                              | Asystent AI    |
| SentenceTransformers | 2.x    | Apache 2.0 | https://github.com/UKPLab/sentence-transformers | Embeddingi     |

---

## 🖋️ Fonts & Media

| Nazwa                            | Licencja              | Źródło                   | Użycie     |
| -------------------------------- | --------------------- | ------------------------ | ---------- |
| Inter font                       | SIL Open Font License | https://rsms.me/inter/   | UI         |
| Google Fonts (Open Sans, Roboto) | OFL                   | https://fonts.google.com | UI tekst   |
| Heroicons                        | MIT                   | https://heroicons.com    | Ikony      |
| Ilustracje kotów (undraw.co)     | MIT                   | https://undraw.co        | Grafiki UI |

---

## 📝 Uwagi końcowe

- Wszystkie licencje są kompatybilne z publikacją w App Store / Google Play.
- Dokumentacja powinna być aktualizowana przy każdej aktualizacji zależności.
- Użycie komponentów GPL lub AGPL należy unikać, chyba że są izolowane lub licencjonowane zgodnie z warunkami.

> 📁 Ten plik znajduje się w `legal/third-party-licenses.md` i podlega aktualizacji przy deployach i releasach.
