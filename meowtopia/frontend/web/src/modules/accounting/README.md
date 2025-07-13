# Moduł Księgowości (@/accounting)

Zoptymalizowany moduł księgowości dla aplikacji Meowtopia z minimalną ilością kodu i maksymalną funkcjonalnością.

## Struktura

```
accounting/
├── types.ts              # Wszystkie typy i interfejsy
├── config.ts             # Konfiguracja, wiadomości, stałe
├── utils.ts              # Funkcje pomocnicze i narzędzia
├── Accounting.tsx        # Główny komponent z nawigacją
├── index.ts              # Eksporty modułu
├── README.md             # Dokumentacja
└── pages/                # Komponenty stron
    ├── Dashboard.tsx     # Dashboard finansowy
    ├── InvoiceList.tsx   # Lista faktur
    ├── InvoiceDetails.tsx # Szczegóły faktury
    ├── Payments.tsx      # Zarządzanie płatnościami
    └── DetailedAccounting.tsx # Szczegółowe wpisy księgowe
```

## Funkcjonalności

### ✅ Zaimplementowane
- **Dashboard finansowy** - przegląd przychodów, wydatków, zysków
- **Zarządzanie fakturami** - lista, szczegóły, filtrowanie, sortowanie
- **Zarządzanie płatnościami** - lista, statusy, metody płatności
- **Szczegółowe wpisy księgowe** - obsługa VAT, dokumenty
- **Admin-only access** - dostęp tylko dla administratorów
- **Responsywny design** - Tailwind CSS, mobile-first
- **Polskie tłumaczenia** - wszystkie teksty w języku polskim

### 🔄 W przygotowaniu
- Raporty finansowe
- Zarządzanie kontami bankowymi
- Kategorie transakcji
- Kalkulacje podatkowe
- Eksport do PDF/CSV
- Integracja z bankami
- OCR dla dokumentów
- Faktury cykliczne

## Użycie

```tsx
import Accounting from '@/modules/accounting';

// W routingu
<Route path="/accounting/*" element={<Accounting />} />
```

## Komponenty

### Accounting.tsx
Główny komponent z sidebar nawigacją i routingiem do wszystkich podstron.

### Dashboard.tsx
Przegląd finansowy z:
- Statystykami miesięcznymi
- Ostatnimi transakcjami
- Top kategoriami wydatków
- Trendami finansowymi

### InvoiceList.tsx
Lista faktur z:
- Filtrowaniem (data, klient, status, typ)
- Sortowaniem
- Paginacją
- Eksportem

### InvoiceDetails.tsx
Szczegóły faktury z:
- Informacjami podstawowymi
- Pozycjami faktury
- Podsumowaniem kwot
- Akcjami (zmiana statusu, edycja, PDF)

### Payments.tsx
Zarządzanie płatnościami z:
- Filtrowaniem (data, metoda, status)
- Sortowaniem
- Zmianą statusów
- Eksportem

### DetailedAccounting.tsx
Szczegółowe wpisy księgowe z:
- Obsługą VAT
- Automatycznymi obliczeniami
- Załącznikami
- Walidacją

## Typy danych

Wszystkie typy są zdefiniowane w `types.ts`:

```tsx
interface Invoice {
  id: string;
  number: string;
  type: 'income' | 'expense';
  clientSupplier: string;
  issueDate: string;
  dueDate: string;
  amount: number;
  vatAmount: number;
  totalAmount: number;
  status: InvoiceStatus;
  // ...
}
```

## Konfiguracja

Konfiguracja w `config.ts`:

```tsx
export const MESSAGES = {
  loading: 'Ładowanie...',
  error: 'Wystąpił błąd',
  success: 'Operacja zakończona pomyślnie',
  // ...
};

export const STATUS_COLORS = {
  paid: 'bg-green-100 text-green-800',
  unpaid: 'bg-yellow-100 text-yellow-800',
  // ...
};
```

## Narzędzia

Funkcje pomocnicze w `utils.ts`:

```tsx
export const formatCurrency = (amount: number): string => {
  return new Intl.NumberFormat('pl-PL', { 
    style: 'currency', 
    currency: 'PLN' 
  }).format(amount);
};

export const filterInvoices = (invoices: Invoice[], filters: InvoiceFilters): Invoice[] => {
  // Logika filtrowania
};
```

## Bezpieczeństwo

- Dostęp tylko dla użytkowników z rolą `ADMIN`
- Walidacja wszystkich danych wejściowych
- Sanityzacja danych przed wyświetleniem

## Responsywność

- Mobile-first design
- Sidebar zamyka się na mobile
- Tabele z scrollowaniem poziomym
- Grid layout dostosowuje się do rozmiaru ekranu

## Wydajność

- Lazy loading komponentów
- Memoizacja obliczeń
- Optymalizacja re-renderów
- Minimalne bundle size

## Rozszerzenia

Moduł jest przygotowany na łatwe dodanie nowych funkcjonalności:

1. Dodaj nowy typ w `types.ts`
2. Dodaj konfigurację w `config.ts`
3. Utwórz komponent w `pages/`
4. Dodaj routing w `Accounting.tsx`

## Zależności

- React 18+
- React Router 6+
- Tailwind CSS
- Iconify React
- Własne komponenty UI (@/components) 