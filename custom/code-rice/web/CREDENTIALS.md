# 🔐 Dane do logowania - Code-Rice

## Wszystkie konta używają hasła: `Test1234!`

---

## 👑 SUPERADMINISTRATOR

**Email:** `superadmin@code-rice.com`  
**Hasło:** `Test1234!`  
**Rola:** `superadmin`

**Dostęp:**
- ✅ Pełny CRUD na wszystkich tabelach
- ✅ Zarządzanie użytkownikami
- ✅ Zarządzanie modułami
- ✅ Ustawienia systemu

---

## 🛡️ ADMINISTRATOR

**Email:** `admin@code-rice.com`  
**Hasło:** `Test1234!`  
**Rola:** `admin`

**Dostęp:**
- ✅ CRUD na modułach i użytkownikach
- ❌ **NIE** może zarządzać superadministratorami
- ❌ **NIE** może zmieniać ról superadministratorów

---

## 💻 DEVELOPER

**Email:** `developer@code-rice.com`  
**Hasło:** `Test1234!`  
**Rola:** `developer`

**Dostęp:**
- ✅ Przeglądanie i edycja modułów
- ✅ Własne projekty
- ❌ **NIE** może zarządzać użytkownikami
- ❌ **NIE** ma dostępu do ustawień systemu

---

## 👤 ZWYKŁY UŻYTKOWNIK

**Email:** `user@code-rice.com`  
**Hasło:** `Test1234!`  
**Rola:** `user`

**Dostęp:**
- ✅ Moje konto
- ✅ Przeglądanie dostępnych modułów
- ❌ **NIE** ma dostępu do panelu admin

---

## 🗄️ PostgreSQL - Dane do połączenia

**Host:** `localhost` lub `devcontainer-postgres`  
**Port:** `5432`  
**Baza danych:** `code-rice`  
**Użytkownik:** `code_rice_user`  
**Hasło:** `code_rice_password`  

**Connection String (host):**
```
postgresql://code_rice_user:code_rice_password@localhost:5432/code-rice?sslmode=disable
```

**Connection String (Docker):**
```
postgresql://code_rice_user:code_rice_password@devcontainer-postgres:5432/code-rice?sslmode=disable
```

---

## 🚀 Szybki start

1. Uruchom serwer:
   ```bash
   cd .project/code_rice/web
   yarn dev
   ```

2. Otwórz: `http://localhost:3002/signin`

3. Zaloguj się jednym z kont powyżej

---

⚠️ **UWAGA:** Te dane są **TYLKO DO TESTOWANIA** w środowisku deweloperskim!

