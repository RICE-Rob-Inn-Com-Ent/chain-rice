# Rice Dev Solidity Smart Contracts

Цей проект містить Solidity смарт-контракти для rice-dev екосистеми, використовуючи Hardhat як інструмент розробки.

## Встановлення

1. Встановіть Node.js та npm (якщо ще не встановлені):
```bash
sudo pacman -S nodejs npm
```

2. Встановіть залежності:
```bash
npm install
```

## Використання

### Компіляція контрактів
```bash
npm run compile
```

### Запуск тестів
```bash
npm test
```

### Деплой на локальну мережу Hardhat
```bash
npm run deploy:hardhat
```

### Деплой на локальну мережу (localhost)
```bash
npm run deploy
```

### Запуск локальної мережі
```bash
npm run node
```

### Zero-Knowledge Tools

#### Компіляція Circom circuits
```bash
npm run compile:circom
```

#### Генерація та верифікація ZK proofs
```bash
npm run zk:proof
```

#### Робота з ZoKrates (Docker)
```bash
npm run zokrates:docker
```

## Структура проекту

- `contracts/` - Solidity контракти
- `scripts/` - Скрипти для деплою та ZK proofs
- `test/` - Тести для контрактів
- `circuits/` - Circom circuits для zero-knowledge proofs
- `hardhat.config.js` - Конфігурація Hardhat

## Доступні мережі

- `hardhat` - Локальна мережа Hardhat (за замовчуванням)
- `localhost` - Локальна мережа на порту 8545
- `ethereum` - Ethereum mainnet (потребує налаштування .env)
- `polygon` - Polygon mainnet (потребує налаштування .env)
- `bsc` - Binance Smart Chain (потребує налаштування .env)
- `avalanche` - Avalanche C-Chain (потребує налаштування .env)
- `arbitrum` - Arbitrum One (потребує налаштування .env)
- `optimism` - Optimism (потребує налаштування .env)

## Налаштування змінних середовища

Для роботи з реальними мережами створіть файл `.env` з наступними змінними:

```env
PRIVATE_KEY=your_private_key_here
ETH_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your_api_key
POLYGON_RPC_URL=https://polygon-mainnet.g.alchemy.com/v2/your_api_key
BSC_RPC_URL=https://bsc-dataseed.binance.org/
AVAX_RPC_URL=https://api.avax.network/ext/bc/C/rpc
ARB_RPC_URL=https://arb1.arbitrum.io/rpc
OPT_RPC_URL=https://mainnet.optimism.io
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## Приклад контракту

Простий контракт `HelloWorld` демонструє базову функціональність:

```solidity
contract HelloWorld {
    string public message;
    
    event MessageSet(string newMessage);
    
    constructor() {
        message = "Hello, Rice Dev!";
    }
    
    function setMessage(string memory _message) public {
        message = _message;
        emit MessageSet(_message);
    }
    
    function getMessage() public view returns (string memory) {
        return message;
    }
}
```

## Розробка

1. Створюйте нові контракти в директорії `contracts/`
2. Додавайте тести в директорію `test/`
3. Використовуйте `npm run compile` для компіляції
4. Запускайте `npm test` для перевірки
5. Деплойте за допомогою скриптів в `scripts/`

## Zero-Knowledge Proofs

Проект підтримує роботу з zero-knowledge proofs через:

### Circom
- **Мова програмування**: Circom для створення arithmetic circuits
- **Компілятор**: circom для генерації R1CS та WASM файлів
- **Приклад**: `circuits/mycircuit.circom` - простий множник

### SnarkJS
- **Бібліотека**: snarkjs для генерації та верифікації proofs
- **Протоколи**: підтримка Groth16, PLONK, FFLONK
- **Скрипт**: `scripts/zk-proof.js` для роботи з proofs

### ZoKrates
- **Інструмент**: ZoKrates через Docker для створення ZK proofs
- **Мова**: Python-подібний синтаксис для circuits

### Приклад використання ZK

```javascript
// Генерація proof
const { proof, publicSignals } = await snarkjs.groth16.fullProve(
    { a: 3, b: 4 },
    "./mycircuit_js/mycircuit.wasm",
    "./mycircuit_pk.zkey"
);

// Верифікація proof
const isValid = await snarkjs.groth16.verify(
    vkey, 
    publicSignals, 
    proof
);
```
