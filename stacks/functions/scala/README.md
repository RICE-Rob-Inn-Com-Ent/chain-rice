# Scala REST API ⭐⭐⭐⭐☆

**Kompleksowa aplikacja REST API napisana w Scali z wykorzystaniem popularnych bibliotek funkcyjnych**

## 🌟 Funkcjonalności

### 👥 Zarządzanie Użytkownikami
- **CRUD Operations**: Tworzenie, odczytywanie, aktualizacja i usuwanie użytkowników
- **Walidacja**: Sprawdzanie poprawności danych (email, wiek, nazwa)
- **Paginacja**: Obsługa dużych zbiorów danych z podziałem na strony
- **Wyszukiwanie**: Wyszukiwanie użytkowników po nazwie i emailu

### 📊 Statystyki i Analiza
- **Statystyki użytkowników**: Liczba aktywnych/nieaktywnych, średni wiek
- **Rozkład wieku**: Grupowanie użytkowników według przedziałów wiekowych
- **Analiza danych**: Najmłodszy/najstarszy użytkownik

### 🔧 Technologie
- **Http4s**: Funkcyjny HTTP server
- **Cats Effect**: Programowanie asynchroniczne i efekty
- **Circe**: Przetwarzanie JSON
- **ScalaTest**: Kompleksowe testy jednostkowe

## 🚀 Szybki Start

### Uruchomienie Aplikacji
```bash
# Kompilacja i uruchomienie
sbt run

# Uruchomienie testów
sbt test

# Kompilacja bez uruchamiania
sbt compile
```

### Przykłady Użycia API

#### Tworzenie Użytkownika
```bash
curl -X POST http://localhost:8080/users \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Jan Kowalski",
    "email": "jan@example.com",
    "age": 30
  }'
```

#### Pobieranie Listy Użytkowników
```bash
# Wszyscy użytkownicy
curl http://localhost:8080/users

# Z paginacją
curl "http://localhost:8080/users?page=1&pageSize=5"
```

#### Wyszukiwanie Użytkowników
```bash
curl "http://localhost:8080/users/search?q=Kowalski"
```

#### Statystyki
```bash
# Statystyki użytkowników
curl http://localhost:8080/statistics/users

# Rozkład wieku
curl http://localhost:8080/statistics/age-distribution

# Liczba aktywnych użytkowników
curl http://localhost:8080/statistics/active-count
```

## 📋 Dostępne Endpointy

### Użytkownicy
- `GET    /users` - Lista użytkowników z paginacją
- `GET    /users/:id` - Pobierz użytkownika po ID
- `POST   /users` - Utwórz nowego użytkownika
- `PUT    /users/:id` - Zaktualizuj użytkownika
- `DELETE /users/:id` - Usuń użytkownika
- `GET    /users/search?q=query` - Wyszukaj użytkowników

### Statystyki
- `GET    /statistics/users` - Statystyki użytkowników
- `GET    /statistics/age-distribution` - Rozkład wieku
- `GET    /statistics/active-count` - Liczba aktywnych użytkowników

## 🏗️ Architektura

Aplikacja wykorzystuje wzorce funkcyjne i czystą architekturę:

- **Models**: Case classes z automatyczną serializacją JSON
- **Services**: Logika biznesowa z obsługą błędów
- **Routes**: HTTP endpoints z walidacją
- **Error Handling**: Typowane błędy z odpowiednimi kodami HTTP

## 🧪 Testy

Kompleksowy zestaw testów obejmuje:
- Testy jednostkowe serwisów
- Testy integracyjne endpointów HTTP
- Testy walidacji danych
- Testy obsługi błędów

```bash
# Uruchomienie wszystkich testów
sbt test

# Uruchomienie konkretnego testu
sbt "testOnly *UserServiceTest"
```

## 📊 Oceny (1–5 gwiazdek)

- **Poziom trudności nauki**: ★★★★☆ (Średniozaawansowany - wymaga znajomości FP)
- **Bogactwo bibliotek/ekosystemu**: ★★★★☆ (Solidny ekosystem JVM + FP)
- **Bogactwo zastosowań w praktyce**: ★★★★☆ (Backend, data processing, web)
- **Wydajność runtime (JVM)**: ★★★★☆ (Wysoka wydajność dzięki JVM)
- **Złożoność narzędzi/buildów**: ★★★★☆ (sbt może być skomplikowany)
- **Jakość kodu**: ★★★★★ (Funkcyjne wzorce, type safety, immutability)

## 🎯 Do czego najlepiej pasuje Scala?

- **Backend Services**: Mikrousługi, API, aplikacje webowe
- **Data Processing**: Spark, przetwarzanie strumieni danych
- **Functional Programming**: Zaawansowane typy, monady, efekty
- **High-Performance**: Aplikacje wymagające wysokiej wydajności
- **Type Safety**: Projekty gdzie bezpieczeństwo typów jest kluczowe

## ⚠️ Kiedy rozważyć inne języki?

- **Prostszy cykl dev**: Kotlin/Java/Go dla szybszego rozwoju
- **Nauka FP od zera**: Python/JavaScript dla prostszych konceptów
- **Szybkie prototypy**: Python/Node.js dla szybkich skryptów
- **Mobile/Desktop**: Kotlin/Swift dla aplikacji mobilnych

## 📚 Użyte Biblioteki

### HTTP i Web
- **Http4s**: Funkcyjny HTTP server i klient
- **Circe**: Parsowanie i generowanie JSON
- **CORS**: Obsługa Cross-Origin Resource Sharing

### Programowanie Funkcyjne
- **Cats**: Biblioteka abstrakcji funkcyjnych
- **Cats Effect**: Efekty asynchroniczne i resource management

### Testowanie
- **ScalaTest**: Framework testowy
- **Cats Effect Testing**: Testy dla efektów asynchronicznych

### Logowanie
- **Log4Cats**: Funkcyjne logowanie
- **Logback**: Implementacja SLF4J

## 🔧 Konfiguracja

Aplikacja używa domyślnych ustawień:
- **Port**: 8080
- **Host**: 0.0.0.0 (wszystkie interfejsy)
- **CORS**: Włączony dla wszystkich źródeł
- **Logging**: SLF4J z Logback

## 📁 Struktura Projektu

```
scala/
├── src/main/scala/
│   ├── main/App.scala              # Główna aplikacja
│   ├── models/                     # Modele danych
│   │   ├── User.scala
│   │   ├── ApiResponse.scala
│   │   └── AppError.scala
│   ├── services/                   # Logika biznesowa
│   │   ├── UserService.scala
│   │   └── StatisticsService.scala
│   └── routes/                     # HTTP endpoints
│       ├── UserRoutes.scala
│       └── StatisticsRoutes.scala
├── src/test/scala/                 # Testy
│   ├── services/
│   └── routes/
├── build.sbt                       # Konfiguracja projektu
└── README.md                       # Dokumentacja
```

## 🚀 Rozszerzenia

Możliwe rozszerzenia aplikacji:
- **Baza danych**: Integracja z PostgreSQL/MongoDB
- **Autentykacja**: JWT, OAuth2
- **Cache**: Redis dla wydajności
- **Monitoring**: Metryki, health checks
- **Docker**: Konteneryzacja aplikacji

Zobacz `ARCHITECTURE.md` dla szczegółów struktury i pomysłów na rozszerzenia.


