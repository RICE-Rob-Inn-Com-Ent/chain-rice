# 🔐 SSL/TLS – Polityka i informacje techniczne

> Dokument definiuje zasady korzystania z certyfikatów SSL/TLS w projekcie Meowtopia w celu zapewnienia poufności i integralności transmisji danych.

---

## 🎯 Cel

Zapewnienie bezpiecznego połączenia między użytkownikiem a serwerami Meowtopia (aplikacja mobilna, web, API, systemy wewnętrzne), zgodnie z wymogami:

- RODO / GDPR
- PCI-DSS (jeśli przetwarzane są dane płatnicze)
- Apple App Store / Google Play
- MiCA – bezpieczeństwo systemów CASP/VASP

---

## 🧾 Obowiązki

### Obowiązek posiadania SSL:

- ✅ Wszystkie strony i subdomeny w domenie `meowtopia.app` muszą posiadać ważny certyfikat SSL/TLS
- ✅ Wszystkie endpointy REST/GraphQL muszą obsługiwać HTTPS
- ✅ Integracje z API zewnętrznymi muszą być szyfrowane (HTTPS / TLS)

---

## 🔧 Implementacja techniczna

- Certyfikaty generowane przez: **Let's Encrypt**, **ZeroSSL** lub **Sectigo**
- Odnowienie: automatyczne (`cron` / `acme.sh` / `certbot`)
- Minimalna wersja protokołu: **TLS 1.2**, preferowane: **TLS 1.3**
- Obsługiwane algorytmy: **ECDHE-RSA-AES128-GCM-SHA256** i nowsze
- Wymuszanie HTTPS: `301 Redirect`, `HSTS`, `secure` cookies, `Content-Security-Policy`

---

## 🧩 Komponenty zabezpieczone certyfikatem SSL:

| Komponent         | Subdomena / Port               | Status |
| ----------------- | ------------------------------ | ------ |
| Strona główna     | `meowtopia.app`                | ✅     |
| Panel admina      | `admin.meowtopia.app`          | ✅     |
| API backend       | `api.meowtopia.app` (port 443) | ✅     |
| CDN / Assets      | `cdn.meowtopia.app`            | ⏳     |
| Dokumentacja      | `docs.meowtopia.app`           | ✅     |
| Interfejs robotów | `iot.meowtopia.app`            | ⏳     |
| WebSocket         | `wss://api.meowtopia.app/ws`   | ✅     |

---

## 📋 Monitoring i raportowanie

- Narzędzia: **SSL Labs**, **uptime monitor**, **Fail2Ban**, **watchdog**
- Alerty przy wygasaniu certyfikatu < 14 dni
- Logi błędów TLS są archiwizowane i analizowane miesięcznie

---

## 📌 Uwagi końcowe

- SSL/TLS jest warunkiem publikacji aplikacji w sklepach Google/Apple
- Bez SSL aplikacja będzie uznawana za **niebezpieczną**
- Dodatkowe zabezpieczenia: DNSSEC, HSTS preload, CAA Record

> _Zaufanie naszych użytkowników to fundament – Meowtopia szyfruje wszystko, co wrażliwe._
