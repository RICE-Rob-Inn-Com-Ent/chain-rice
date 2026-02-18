# Konfiguracja S3/MinIO dla Meowtopia

## Instalacja zależności

```bash
cd web
yarn add @aws-sdk/client-s3
```

## Konfiguracja zmiennych środowiskowych

Dodaj do `.env` lub `.env.local`:

### Opcja 1: Użycie S3/MinIO (domyślne)

```env
# MinIO/S3 Configuration
MINIO_ENDPOINT=http://devcontainer-minio:9000
MINIO_ACCESS_KEY=minioadmin
MINIO_SECRET_KEY=minioadmin
MINIO_USE_SSL=false
S3_BUCKET=meowtopia-products
S3_REGION=us-east-1
STORAGE_BASE_URL=http://localhost:9000
```

### Opcja 2: Lokalny storage (fallback automatyczny)

Jeśli S3 nie działa lub chcesz wymusić lokalny storage:

```env
USE_LOCAL_STORAGE=true
```

System automatycznie użyje lokalnego storage gdy:
- `USE_LOCAL_STORAGE=true`
- S3/MinIO nie jest dostępny
- Wystąpi błąd podczas uploadu do S3

## Lokalny Storage (Fallback)

Gdy S3 nie działa, system automatycznie zapisuje zdjęcia lokalnie do:
```
public/uploads/products/{kategoria}/{szyfrowana_nazwa}.{ext}
```

### Format nazw plików:
- **Szyfrowane**: `{hash}_{kategoria}_{nazwa_produktu}_{index}.{ext}`
- **Hash**: SHA256 z kategorii, nazwy produktu, timestamp i indexu
- **Kategoria**: znormalizowana (np. "kawa", "herbata", "dzieła-artystów")
- **Nazwa produktu**: znormalizowana z bazy danych (max 50 znaków)

### Przykład:
```
public/uploads/products/kawa/a1b2c3d4_kawa_arabica_premium_0.jpg
public/uploads/products/herbata/e5f6g7h8_herbata_zielona_sencha_0.jpg
```

## Utworzenie bucketu w MinIO (jeśli używasz S3)

1. Otwórz konsolę MinIO: http://localhost:9001
2. Zaloguj się (domyślnie: minioadmin/minioadmin)
3. Utwórz bucket o nazwie `meowtopia-products`
4. Ustaw bucket jako publiczny (Policy: `readonly`) jeśli chcesz publiczny dostęp do zdjęć

## Jak działa system

1. **Próba uploadu do S3** - jeśli S3 jest skonfigurowany i dostępny
2. **Automatyczny fallback** - jeśli S3 nie działa, zapisuje lokalnie
3. **Lokalny storage** - zdjęcia zapisywane z szyfrowanymi nazwami na podstawie kategorii i nazwy produktu z bazy danych

## Uwagi

- Lokalne pliki są dostępne publicznie przez `/uploads/products/...`
- Nazwy plików są szyfrowane dla bezpieczeństwa
- Katalogi tworzone są automatycznie
- System automatycznie wykrywa czy S3 działa i przełącza się na lokalny storage w razie potrzeby

