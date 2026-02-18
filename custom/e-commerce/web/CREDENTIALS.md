# 🔐 Dane do logowania - MeoWTopia

## Wszystkie konta używają hasła: `Test1234!`

---

## 👑 SUPERADMINISTRATOR

**Email:** `superadmin@meowTopia.com`  
**Hasło:** `Test1234!`  
**Rola:** `superadmin`

**Dostęp:**
- ✅ Pełny CRUD na wszystkich tabelach
- ✅ Zarządzanie użytkownikami
- ✅ Zarządzanie klientami
- ✅ Zarządzanie zamówieniami
- ✅ Program lojalnościowy
- ✅ Ustawienia systemu

---

## 🛡️ ADMINISTRATOR

**Email:** `admin@meowTopia.com`  
**Hasło:** `Test1234!`  
**Rola:** `admin`

**Dostęp:**
- ✅ CRUD na klientach i zamówieniach
- ✅ Program lojalnościowy
- ❌ **NIE** może zarządzać superadministratorami
- ❌ **NIE** może zmieniać ról superadministratorów

---

## 📊 MANAGER

**Email:** `manager@meowTopia.com`  
**Hasło:** `Test1234!`  
**Rola:** `manager`

**Dostęp:**
- ✅ Przeglądanie zamówień
- ✅ Zarządzanie klientami
- ✅ Program lojalnościowy
- ❌ **NIE** może zarządzać użytkownikami
- ❌ **NIE** ma dostępu do ustawień systemu

---

## 👤 ZWYKŁY UŻYTKOWNIK

**Email:** `user@meowTopia.com`  
**Hasło:** `Test1234!`  
**Rola:** `user`

**Dostęp:**
- ✅ Moje konto
- ✅ Moje zamówienia
- ✅ Program lojalnościowy
- ❌ **NIE** ma dostępu do panelu admin

---

## 🗄️ PostgreSQL - Dane do połączenia

**Host:** `localhost` lub `devcontainer-postgres`  
**Port:** `5432`  
**Baza danych:** `meowtopia`  
**Użytkownik:** `meowtopia_user`  
**Hasło:** `meowtopia_password`  

**Connection String (host):**
```
postgresql://meowtopia_user:meowtopia_password@localhost:5432/meowtopia?sslmode=disable
```

**Connection String (Docker):**
```
postgresql://meowtopia_user:meowtopia_password@devcontainer-postgres:5432/meowtopia?sslmode=disable
```

---

## 🚀 Szybki start

1. Uruchom serwer:
   ```bash
   cd .project/meowtopia/web
   yarn dev
   ```

2. Otwórz: `http://localhost:3004/signin`

3. Zaloguj się jednym z kont powyżej

---

⚠️ **UWAGA:** Te dane są **TYLKO DO TESTOWANIA** w środowisku deweloperskim!

