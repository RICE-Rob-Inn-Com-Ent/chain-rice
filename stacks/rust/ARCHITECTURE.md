# Chain Rice CW20 Token Contract Architecture

## 🏗️ Struktura Projektu

```
src/
├── lib.rs          # Główne entry points (instantiate, execute, query)
├── main.rs         # Kompatybilność z cargo (nie używane w kontrakcie)
├── msg.rs          # Definicje wiadomości i struktur odpowiedzi
├── state.rs        # Struktury danych i storage items
├── error.rs        # Custom error types
└── contract.rs     # Testy jednostkowe
```

## 🔄 Flow Kontraktu

### 1. Instantiate
- Tworzy nowy token z nazwą, symbolem, decimals i początkową podażą
- Ustawia właściciela kontraktu
- Inicjalizuje storage z konfiguracją i informacjami o tokenach

### 2. Execute Operations
- **Mint**: Tylko właściciel może tworzyć nowe tokeny
- **Burn**: Tylko właściciel może spalać tokeny
- **Transfer**: Loguje transfer (w uproszczonej wersji)
- **UpdateOwner**: Zmiana właściciela kontraktu

### 3. Query Operations
- **GetConfig**: Zwraca konfigurację kontraktu
- **GetTokenInfo**: Zwraca informacje o tokenach (podaż, wyemitowane)
- **GetBalance**: Zwraca saldo adresu (uproszczone)

## 🗄️ Storage Structure

```rust
// Konfiguracja kontraktu
CONFIG: Item<Config> {
    owner: Addr,           // Właściciel kontraktu
    name: String,          // Nazwa tokenu
    symbol: String,        // Symbol tokenu
    decimals: u8,          // Liczba miejsc dziesiętnych
    total_supply: u128,    // Całkowita podaż
}

// Informacje o tokenach
TOKEN_INFO: Item<TokenInfo> {
    total_supply: u128,    // Aktualna podaż
    minted: u128,          // Wyemitowane tokeny
}
```

## 🔒 Security Patterns

### Access Control
- Wszystkie operacje mint/burn wymagają uprawnień właściciela
- Walidacja adresów przed zapisem do storage
- Sprawdzanie sald przed operacjami burn

### Error Handling
- Custom error types dla różnych scenariuszy
- Proper error propagation z CosmWasm StdError
- Informacyjne komunikaty błędów

## 🧪 Testing Strategy

### Unit Tests
- Testy inicjalizacji kontraktu
- Testy operacji mint/burn
- Testy autoryzacji (unauthorized access)
- Testy zmiany właściciela

### Test Framework
- Używa `cw-multi-test` dla symulacji blockchain
- Mock app environment
- Contract wrapper dla testów

## 🚀 Rozszerzenia i Ulepszenia

### Możliwe Rozszerzenia
1. **Balance Tracking**: Implementacja pełnego śledzenia sald per adres
2. **Allowances**: System uprawnień dla transferów
3. **Pausable**: Możliwość zatrzymania kontraktu
4. **Upgradeable**: Możliwość aktualizacji kodu kontraktu
5. **Events**: Emitowanie eventów dla wszystkich operacji
6. **Batch Operations**: Operacje na wielu tokenach jednocześnie

### Production Ready Features
1. **Migration**: Obsługa migracji stanu kontraktu
2. **Admin Functions**: Dodatkowe funkcje administracyjne
3. **Fee System**: System opłat za operacje
4. **Whitelist**: Lista dozwolonych adresów
5. **Time Locks**: Opóźnienia dla krytycznych operacji

## 📊 Performance Considerations

- Minimal storage operations
- Efficient serialization/deserialization
- Gas optimization patterns
- Memory management best practices

## 🔧 Development Workflow

1. **Local Development**: `cargo test`
2. **Contract Building**: `cargo build --release`
3. **Schema Generation**: `cargo schema` (jeśli dodane)
4. **Integration Testing**: Testy z prawdziwym blockchain

## 📚 Learning Resources

- [CosmWasm Documentation](https://docs.cosmwasm.com/)
- [Rust Smart Contracts](https://docs.rs/cosmwasm-std/)
- [CW20 Standard](https://github.com/CosmWasm/cw-plus/tree/main/contracts/cw20-base)


