# Przykładowe paragony i faktury

Ten folder zawiera przykładowe paragony i faktury w formacie obrazów do testowania OCR.

## Struktura

```
receipts/
├── README.md
├── sample_receipt_1.jpg    # Przykładowy paragon 1
├── sample_receipt_2.jpg    # Przykładowy paragon 2
├── sample_invoice_1.pdf    # Przykładowa faktura 1
└── expected_output.json    # Oczekiwane dane wyekstrahowane
```

## Format oczekiwanych danych

Każdy paragon/faktura powinien zawierać:
- Data wystawienia
- Numer paragonu/faktury
- Sprzedawca (nazwa, NIP, adres)
- Pozycje (produkty/usługi z cenami)
- Kwota całkowita
- VAT
- Metoda płatności

## Użycie

1. Umieść pliki obrazów w tym folderze
2. Użyj API `/api/ocr` do przetworzenia
3. Porównaj wynik z oczekiwanymi danymi w `expected_output.json`










































