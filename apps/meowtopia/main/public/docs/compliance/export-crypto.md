# 🔐 Export Compliance – Zgłoszenie kryptografii / środek płatniczy

> Dokument przygotowany na potrzeby legalizacji aplikacji Meowtopia z wykorzystaniem technologii szyfrowania, zgodnie z wymaganiami App Store, Google Play oraz przepisami eksportowymi UE i USA.

---

## 🧾 Dane aplikacji

- **Nazwa aplikacji:** Meowtopia
- **Typ:** Gra Web3, która łączy świat fizyczny i cyfrowy
- **Platformy:** [x] Android, [x] iOS, [x] Web
- **Rodzaj szyfrowania:**

  - [x] TLS 1.2 / 1.3 (SSL)
  - [x] AES-256 dla danych lokalnych
  - [x] Ed25519 / secp256k1 dla podpisów i kluczy
  - [x] Custom key management dla tokenów lojalnościowych

---

## 🌍 Jurysdykcja i wymogi eksportowe

### 🇺🇸 EAR (Export Administration Regulations – USA)

- Aplikacja wykorzystuje standardowe protokoły (TLS) oraz kryptografię do autoryzacji transakcji
- Nie zawiera algorytmów niejawnych ani customowych mechanizmów bez dokumentacji
- Zgodna z kategorią **Mass Market Encryption Software (ECCN 5D992)**
- Wymaga zgłoszenia do **BIS (Bureau of Industry and Security)** jako produkt kwalifikujący się do ogólnego zezwolenia (NLR – No License Required), ale konieczne jest **annual self-classification report**

### 🇪🇺 Przepisy UE (rozporządzenie 428/2009 / nowa lista DU)

- Zastosowane szyfrowanie podlega kontroli wywozu (CN: 8523 / 5A002)
- Wymagana klasyfikacja aplikacji jako **środek płatniczy** (jeśli tokeny mają wymienialną wartość)
- Kraj eksportu: Polska
- Jurysdykcja docelowa: globalna (w tym USA, UE, UK, Kanada, Australia)
- Obowiązek zgłoszenia do polskiego **Departamentu Handlu i Współpracy Międzynarodowej Ministerstwa Rozwoju**

---

## 📄 Zakres funkcji kryptograficznych

| Funkcja           | Opis                                 | Zastosowanie                     |
| ----------------- | ------------------------------------ | -------------------------------- |
| TLS 1.2+          | Standardowe szyfrowanie transportowe | Komunikacja z API i blockchainem |
| AES-256           | Szyfrowanie danych lokalnych         | Tokeny, stan portfela            |
| Ed25519/secp256k1 | Klucze i podpisy                     | Portfele, transakcje, DAO        |
| Custom key-store  | Lokalna izolacja klucza              | Offline backup tokenów           |

---

## 📑 Wymagane dokumenty do zgłoszenia

- [x] Opis kryptografii i jej użycia (`crypto-architecture.pdf`)
- [x] Link do aplikacji i repozytorium kodu (`https://github.com/...`)
- [x] Certyfikat SSL serwera produkcyjnego
- [x] Opis środków bezpieczeństwa i audytu (`audit-report.md` lub ISO 27001)
- [x] Deklaracja, że aplikacja nie wspiera użycia militarnych/niejawnych algorytmów

---

## 📬 Gdzie zgłosić

### 🇵🇱 Polska

- [x] Ministerstwo Rozwoju i Technologii, Departament Współpracy Międzynarodowej
- [x] ePUAP / SEKAP – eksport technologii podlegającej kontroli
- [x] Wzór pisma: `export-declaration-pl.md`

### 🇺🇸 USA (jeśli publikacja w App Store)

- [x] Rejestracja w BIS
- [x] Przesłanie **self-classification report** przez SNAP-R
- [x] Opcjonalnie: CCATS dla ECCN 5D002 jeśli wymagane (dla wniosków o pełną klasyfikację)

---

## 📆 Harmonogram i obowiązki

| Krok                               | Termin                           | Odpowiedzialny           |
| ---------------------------------- | -------------------------------- | ------------------------ |
| Przygotowanie raportu eksportowego | ASAP                             | CTO / Compliance Officer |
| Zgłoszenie do MRiT (Polska)        | do 7 dni od publikacji aplikacji | Legal Team               |
| Rejestracja w BIS (USA)            | przed publikacją na App Store    | CTO                      |
| Dokumentacja zmian kryptografii    | ciągła aktualizacja              | DevSec Team              |

---

> 📌 Ten plik może być używany do wniosków o klasyfikację eksportową i zgłoszenia aplikacji z kryptografią do sklepów i organów regulacyjnych. Wersja do druku: `export-crypto.pdf`
