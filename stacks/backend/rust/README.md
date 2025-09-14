# Chain Rice Smart Contracts ⭐⭐⭐⭐⭐

**Kompleksowy zestaw smart contractów napisanych w Rust dla blockchain Cosmos**

## 🌟 Dostępne Kontrakty

### 🪙 CW20 Token Contract
- **Mint Tokenów**: Tworzenie nowych tokenów (tylko właściciel)
- **Burn Tokenów**: Spalanie tokenów (tylko właściciel)  
- **Transfer**: Przesyłanie tokenów między adresami
- **Zarządzanie Właścicielem**: Zmiana właściciela kontraktu
- **Query Functions**: Sprawdzanie stanu kontraktu i sald

### 🏛️ DAO Governance Contract
- **Tworzenie Propozycji**: Administracja może tworzyć propozycje głosowania
- **Głosowanie**: Użytkownicy mogą głosować za/przeciw propozycjom
- **Wykonywanie Propozycji**: Automatyczne wykonywanie po zakończeniu głosowania
- **Konfiguracja**: Ustawienia okresu głosowania, kworum i progu

### 🎨 NFT Collection Contract
- **Mint NFT**: Tworzenie nowych tokenów NFT (tylko właściciel)
- **Transfer**: Przesyłanie NFT między adresami
- **Approve**: Upoważnianie innych do zarządzania NFT
- **Burn**: Spalanie NFT
- **Metadata**: Obsługa metadanych i URI

## 🚀 Szybki Start

### Generowanie Kontraktów
```bash
# Generuj CW20 token
make generate-cw20 NAME=my-token

# Generuj DAO
make generate-dao NAME=my-dao

# Generuj NFT collection
make generate-nft NAME=my-nfts
```

### Budowanie Wszystkich Kontraktów
```bash
make build
```

### Testy
```bash
make test
```

### Czyszczenie
```bash
make clean
```

## 📋 Struktura Kontraktu

### InstantiateMsg
```rust
{
    "name": "Chain Rice Token",
    "symbol": "CRT", 
    "decimals": 6,
    "initial_supply": 1000000
}
```

### ExecuteMsg
```rust
// Mint nowych tokenów
{
    "mint": {
        "to": "cosmos1...",
        "amount": "500000"
    }
}

// Spal tokeny
{
    "burn": {
        "from": "cosmos1...",
        "amount": "200000"
    }
}

// Transfer tokenów
{
    "transfer": {
        "to": "cosmos1...",
        "amount": "100000"
    }
}

// Zmień właściciela
{
    "update_owner": {
        "new_owner": "cosmos1..."
    }
}
```

### QueryMsg
```rust
// Pobierz konfigurację
{
    "get_config": {}
}

// Pobierz informacje o tokenach
{
    "get_token_info": {}
}

// Pobierz saldo
{
    "get_balance": {
        "address": "cosmos1..."
    }
}
```

## 🏗️ Architektura

Kontrakt składa się z następujących modułów:

- **lib.rs**: Główne funkcje entry_point (instantiate, execute, query)
- **msg.rs**: Definicje wiadomości (InstantiateMsg, ExecuteMsg, QueryMsg)
- **state.rs**: Struktury danych i storage
- **error.rs**: Obsługa błędów
- **contract.rs**: Testy jednostkowe

## 🔒 Bezpieczeństwo

- Tylko właściciel może mintować/spalać tokeny
- Walidacja adresów przed zapisem
- Sprawdzanie sald przed operacjami
- Proper error handling

## 🚀 Deployment i Interakcja

### Deployment Kontraktów
```bash
# Deploy CW20 token
./scripts/deploy.sh -c osmosis-1 -r https://rpc.osmosis.zone -k mykey -n rice-token -t cw20

# Deploy DAO
./scripts/deploy.sh -c juno-1 -r https://rpc.juno.zone -k mykey -n rice-dao -t dao

# Deploy NFT collection
./scripts/deploy.sh -c osmosis-1 -r https://rpc.osmosis.zone -k mykey -n rice-nfts -t nft
```

### Interakcja z Kontraktami
```bash
# Query konfiguracji
./scripts/interact.sh -c osmosis-1 -r https://rpc.osmosis.zone -k mykey -a cosmos123... -t cw20 query CONFIG

# Mint tokenów
./scripts/interact.sh -c osmosis-1 -r https://rpc.osmosis.zone -k mykey -a cosmos123... -t cw20 mint 1000000

# Transfer tokenów
./scripts/interact.sh -c osmosis-1 -r https://rpc.osmosis.zone -k mykey -a cosmos123... -t cw20 transfer cosmos456... 500000

# Tworzenie propozycji DAO
./scripts/interact.sh -c juno-1 -r https://rpc.juno.zone -k mykey -a cosmos789... -t dao create-proposal "New Feature Proposal"

# Głosowanie w DAO
./scripts/interact.sh -c juno-1 -r https://rpc.juno.zone -k mykey -a cosmos789... -t dao vote 1 yes
```

## 📊 Przykłady Użycia

### CW20 Token
```bash
# 1. Instantiate kontrakt
cosmosd tx wasm instantiate [code_id] '{"name":"Chain Rice Token","symbol":"CRT","decimals":6,"initial_supply":"1000000"}' --from admin --label "CRT Token"

# 2. Mint nowych tokenów
cosmosd tx wasm execute [contract_addr] '{"mint":{"to":"cosmos1user...","amount":"500000"}}' --from admin

# 3. Sprawdź informacje o tokenach
cosmosd query wasm contract-state smart [contract_addr] '{"get_token_info":{}}'
```

### DAO Governance
```bash
# 1. Instantiate DAO
cosmosd tx wasm instantiate [code_id] '{"name":"Chain Rice DAO","description":"Governance for Chain Rice","voting_period":604800,"quorum":100,"threshold":0.5}' --from admin --label "Rice DAO"

# 2. Tworzenie propozycji
cosmosd tx wasm execute [contract_addr] '{"create_proposal":{"title":"New Feature","description":"Add new feature","proposal_type":"governance"}}' --from admin

# 3. Głosowanie
cosmosd tx wasm execute [contract_addr] '{"vote":{"proposal_id":1,"vote":"yes"}}' --from user
```

### NFT Collection
```bash
# 1. Instantiate NFT collection
cosmosd tx wasm instantiate [code_id] '{"name":"Chain Rice NFTs","symbol":"CRN","base_uri":"https://chain-rice.com/metadata/","max_supply":10000}' --from admin --label "Rice NFTs"

# 2. Mint NFT
cosmosd tx wasm execute [contract_addr] '{"mint":{"to":"cosmos1user...","token_id":"1","token_uri":"https://chain-rice.com/metadata/1.json"}}' --from admin

# 3. Transfer NFT
cosmosd tx wasm execute [contract_addr] '{"transfer":{"to":"cosmos1recipient...","token_id":"1"}}' --from user
```

## 🛠️ Dostępne Komendy

### Makefile Commands
```bash
make help                    # Pokaż pomoc
make generate-cw20 NAME=...  # Generuj CW20 token
make generate-dao NAME=...   # Generuj DAO contract
make generate-nft NAME=...   # Generuj NFT collection
make build                   # Buduj wszystkie kontrakty
make test                    # Uruchom testy
make clean                   # Wyczyść artefakty
make list                    # Lista dostępnych kontraktów
make examples                # Generuj przykładowe kontrakty
```

### Script Commands
```bash
# Generowanie kontraktów
./scripts/generate_contract.sh -n contract-name -t contract-type

# Deployment
./scripts/deploy.sh -c chain-id -r rpc-url -k key-name -n contract-name -t contract-type

# Interakcja
./scripts/interact.sh -c chain-id -r rpc-url -k key-name -a contract-address -t contract-type command
```

## 📁 Struktura Projektu

```
rust/
├── src/                    # Oryginalny CW20 contract
├── contracts/              # Wygenerowane kontrakty
│   ├── rice-token/         # CW20 token example
│   ├── rice-dao/           # DAO governance example
│   └── rice-nfts/          # NFT collection example
├── scripts/                # Skrypty pomocnicze
│   ├── generate_contract.sh
│   ├── deploy.sh
│   └── interact.sh
├── Makefile                # Komendy automatyzacji
└── README.md               # Dokumentacja
```

## ⭐ Ocena Umiejętności

**Poziom: Średniozaawansowany** - Demonstruje solidne zrozumienie:
- CosmWasm framework
- Rust ownership i error handling
- Smart contract patterns
- Test-driven development
- Blockchain security principles
- Automation i DevOps practices
- Multi-contract architecture

Zobacz `ARCHITECTURE.md` dla szczegółów struktury i pomysłów na rozszerzenia.


