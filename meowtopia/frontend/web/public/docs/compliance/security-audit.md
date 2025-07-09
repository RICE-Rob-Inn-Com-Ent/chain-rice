# 🛡️ Security Audit Plan – Meowtopia

> Dokument określa ramy, cele i etapy przeprowadzania audytu bezpieczeństwa systemu Meowtopia – platformy łączącej technologie blockchain, robotykę, AI oraz aplikacje mobilne/webowe w ramach działań kawiarnianych i edukacyjnych.

---

## 🎯 Cel audytu

- Weryfikacja zgodności z normami: **ISO 27001**, **PCI DSS**, **GDPR**, **MiCA**
- Sprawdzenie realnego poziomu ochrony danych (klientów, partnerów, transakcji)
- Ocena odporności systemu na cyberataki, nadużycia oraz awarie
- Identyfikacja słabych punktów w architekturze aplikacji (mobile/web/backend)

---

## 🔍 Zakres audytu

### Obszary objęte audytem:

- 🔐 Autoryzacja, logowanie, reset hasła
- 📦 Przesyłanie i przechowywanie danych wrażliwych (osobowe, płatnicze)
- 🌍 Komunikacja z zewnętrznymi API i partnerami (np. płatności, NGO)
- 🧠 Algorytmy AI, interakcje z użytkownikiem
- 🧾 Smart kontrakty (blockchain) i ich audyt wewnętrzny
- 🤖 Roboty / POS / hardware IoT (jeśli połączone z siecią)

---

## 📆 Harmonogram i etapy

| Etap                            | Opis                                                | Termin  |
| ------------------------------- | --------------------------------------------------- | ------- |
| 1. Przygotowanie                | Zebranie architektury i wewnętrznych procedur       | Q3 2025 |
| 2. Testy penetracyjne           | Manualne i automatyczne testy (blackbox + whitebox) | Q4 2025 |
| 3. Przegląd kodu (code review)  | Audyt repozytoriów frontend/backend/solidity/go     | Q4 2025 |
| 4. Audyt fizyczny (POS, roboty) | Sprawdzenie punktów fizycznych (logi, sieci)        | Q1 2026 |
| 5. Raport i rekomendacje        | Ocena ryzyk, zalecenia, ocena zgodności z ISO/PCI   | Q1 2026 |

---

## 🧩 Narzędzia i metody

- 🔎 OWASP ZAP / Burp Suite – testy aplikacji webowych
- 🧪 Nessus / OpenVAS – skan podatności sieci/systemów
- 📜 Statyczna analiza kodu (SonarQube, Bandit, CodeQL)
- 🔐 Manualne testy exploitable endpoints (POST/GET, Auth Bypass, SSRF)
- 📋 Checklisty zgodności z PCI-DSS, ISO 27001, GDPR, MiCA
- 🧠 Audyt promptów i modeli AI w interfejsie

---

## 🧾 Wynik i dokumentacja

- 📄 Raport bezpieczeństwa z oceną ryzyk
- ✅ Lista zaleceń i niezgodności
- 📎 Materiały uzupełniające: logi, screeny, skany, test case'y
- 🔁 Plan poprawczy i kontrola wdrożenia zmian (follow-up)

---

## 📌 Uwagi końcowe

- Audyt ma charakter niezależny i wewnętrzny – poprzedza ewentualne zlecenie dla QSA lub zewnętrznej firmy certyfikującej.
- Może być podstawą do uzyskania:
  - Licencji **VASP/CASP** (MiCA)
  - Certyfikacji **ISO 27001 / 27701**
  - Zgodności z **PCI DSS**, **DORA**, **GDPR**

> _Bezpieczeństwo to nie projekt – to proces. Meowtopia prowadzi działania ciągłe na rzecz cyberodporności._
