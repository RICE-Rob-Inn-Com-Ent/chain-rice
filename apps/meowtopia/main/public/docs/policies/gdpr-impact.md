# 📊 Ocena skutków dla ochrony danych (DPIA)

> Niniejszy dokument stanowi analizę ryzyka i skutków związanych z przetwarzaniem danych osobowych w ramach platformy Meowtopia, zgodnie z art. 35 RODO.

---

## 1. Opis projektu

**Meowtopia** to zintegrowana platforma łącząca:

- aplikację mobilną (Android/iOS/Web),
- blockchain (program lojalnościowy, NFT, DAO),
- interaktywne systemy robotyczne w przestrzeni kawiarni,
- moduły analityczne i grywalizację.

Platforma pozwala użytkownikom m.in. na:

- zakładanie konta,
- udział w programie lojalnościowym,
- interakcję z robotami w kawiarniach,
- głosowanie i zarządzanie tokenami.

---

## 2. Rodzaje danych osobowych

Przetwarzane dane obejmują:

- dane identyfikacyjne: imię, e-mail, numer telefonu
- dane techniczne: IP, user-agent, sesja logowania
- dane lokalizacyjne (dobrowolnie)
- identyfikatory blockchain/Web3 (adresy portfeli)
- dane dotyczące aktywności (np. głosowania DAO, zakupy)
- dane dotyczące preferencji, interakcji, historii lojalności

---

## 3. Osoby, których dane dotyczą

- Użytkownicy aplikacji Meowtopia
- Uczestnicy DAO
- Klienci kawiarni
- Partnerzy instytucjonalni (NGO, restauracje, firmy)

---

## 4. Cel przetwarzania danych

- świadczenie usług cyfrowych i fizycznych (kawiarnia, aplikacja)
- uczestnictwo w programie lojalnościowym i głosowaniach
- ochrona bezpieczeństwa platformy
- personalizacja i analiza zachowań użytkownika
- weryfikacja tożsamości (KYC/AML)
- zgodność z przepisami prawa (RODO, MiCA, PSD2)

---

## 5. Podstawy prawne

- Art. 6 ust. 1 lit. a) – zgoda użytkownika
- Art. 6 ust. 1 lit. b) – realizacja umowy (świadczenie usług)
- Art. 6 ust. 1 lit. c) – obowiązek prawny (np. KYC, AML)
- Art. 6 ust. 1 lit. f) – uzasadniony interes (np. ochrona systemu)

---

## 6. Analiza ryzyka

| Potencjalne ryzyko               | Prawdopodobieństwo | Wpływ          | Działania minimalizujące                     |
| -------------------------------- | ------------------ | -------------- | -------------------------------------------- |
| Nieuprawniony dostęp             | średnie            | wysokie        | SSL, uwierzytelnianie 2FA, logowanie dostępu |
| Błąd aplikacji                   | niskie             | średnie        | CI/CD, testy regresyjne, monitoring          |
| Nadużycie danych przez partnerów | niskie             | wysokie        | Umowy DPA, lista subprocesorów               |
| Zgubienie klucza blockchain      | niskie             | bardzo wysokie | Ostrzeżenia, lokalna kopia, opcja multisig   |
| Niezgodność z RODO               | niskie             | bardzo wysokie | Zatrudnienie DPO, DPIA, audyty               |

---

## 7. Prawa użytkowników

- dostęp do danych
- poprawianie danych
- usunięcie danych („prawo do bycia zapomnianym”)
- ograniczenie przetwarzania
- sprzeciw wobec przetwarzania
- przenoszenie danych
- skarga do organu nadzorczego (PUODO)

---

## 8. Wnioski i rekomendacje

- Ryzyko uznaje się za **akceptowalne**, przy wdrożeniu technicznych i organizacyjnych środków zabezpieczających.
- Zaleca się **cykliczną ocenę DPIA** (co 12 miesięcy lub przy dużej zmianie w systemie).
- Należy zapewnić czytelne interfejsy zgód i realizację praw użytkownika.
- Wdrożyć szkolenia zespołu i partnerów w zakresie ochrony danych.

---

## 9. Odpowiedzialność

Osoba odpowiedzialna za wdrożenie DPIA i kontrolę zgodności z RODO:

**Inspektor Ochrony Danych (DPO)**  
📧 dpo@meowtopia.app  
📧 legal@meowtopia.app

---

> Dokument ten stanowi część systemu zarządzania zgodnością danych osobowych i może być udostępniony organowi nadzorczemu (PUODO) w przypadku kontroli.
