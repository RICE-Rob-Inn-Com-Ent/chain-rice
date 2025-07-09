# 💳 PCI DSS – Zgodność z bezpieczeństwem danych kart płatniczych

> Dokument przygotowawczy do uzyskania zgodności z **PCI DSS (Payment Card Industry Data Security Standard)** dla Meowtopia – ekosystemu obejmującego aplikacje mobilne, webowe i punkty sprzedaży w kawiarniach.

---

## 🎯 Cel

Celem wdrożenia PCI DSS jest zapewnienie bezpiecznego przetwarzania, przechowywania i przesyłania danych kart płatniczych klientów, w tym danych PAN, CVV, daty ważności i nazwiska właściciela.

---

## 📌 Zakres

Standard dotyczy:

- Aplikacji mobilnych i webowych obsługujących płatności
- Backendów przetwarzających transakcje
- Punktów fizycznych (POS z robotami w kawiarniach)
- Interfejsów API do płatności i loyalty tokenów (jeśli łączone z fiat)

---

## 🔒 Główne wymagania PCI DSS

1. **Bezpieczna sieć**

   - 🔐 Firewall między systemami wewnętrznymi a zewnętrznymi
   - ❌ Brak domyślnych haseł dostępowych

2. **Ochrona danych karty**

   - 🔒 Szyfrowanie danych PAN w spoczynku i transmisji (AES-256, TLS 1.3)
   - 🚫 Brak przechowywania CVV po autoryzacji

3. **Zarządzanie podatnościami**

   - 🛠️ Regularne aktualizacje systemów i komponentów
   - 🔍 Skany podatności i testy penetracyjne

4. **Kontrola dostępu**

   - 📛 Unikalne ID użytkowników z dostępem do danych kart
   - ⏳ Ograniczenia czasowe, logowanie i rejestrowanie prób

5. **Monitorowanie i testowanie**

   - 📊 Monitorowanie logów bezpieczeństwa
   - 📅 Codzienne kontrole integralności plików i ruchu sieciowego

6. **Polityki bezpieczeństwa**
   - 📘 Spisana polityka bezpieczeństwa danych kart (`card-security-policy.md`)
   - 👥 Szkolenie personelu w zakresie PCI

---

## 🧩 Dokumenty uzupełniające

| Dokument                     | Cel                        | Plik                       |
| ---------------------------- | -------------------------- | -------------------------- |
| Polityka bezpieczeństwa kart | Główne zasady PCI DSS      | `card-security-policy.md`  |
| Procedury inspekcji POS      | Offline i fizyczna ochrona | `pos-security.md`          |
| Skany podatności i raporty   | Dowody audytowe            | `audit-vulnerabilities.md` |
| Plan reagowania na incydenty | Obowiązkowy                | `incident-plan.md`         |

---

## 📆 Harmonogram wdrożenia

| Etap                             | Status |
| -------------------------------- | ------ |
| Mapowanie przepływu danych kart  | ✖️     |
| Wdrożenie szyfrowania end-to-end | ✖️     |
| Dokumentacja polityk PCI         | ✖️     |
| Audyt wstępny wewnętrzny         | ✖️     |
| Certyfikacja przez QSA           | ✖️     |

---

## 🧾 Uwagi końcowe

Zgodność z PCI DSS wymagana jest w przypadku:

- Akceptowania kart płatniczych (online lub offline)
- Obsługi płatności z poziomu aplikacji
- Przetwarzania danych PAN lub ich przechowywania w logach

> _Bezpieczeństwo płatności jest fundamentem zaufania użytkowników. Meowtopia zapewnia zgodność na każdym etapie._
