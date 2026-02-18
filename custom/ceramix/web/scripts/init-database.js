#!/usr/bin/env node

/**
 * Skrypt inicjalizacji bazy danych Ceramix
 * Uruchamia wszystkie potrzebne migracje i schematy
 */

const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

// Wczytaj zmienne środowiskowe z .env.local
const envPath = path.join(__dirname, '..', '.env.local');
if (fs.existsSync(envPath)) {
  const envContent = fs.readFileSync(envPath, 'utf8');
  envContent.split('\n').forEach(line => {
    const match = line.match(/^([^=]+)=(.*)$/);
    if (match) {
      const key = match[1].trim();
      const value = match[2].trim().replace(/^["']|["']$/g, '');
      process.env[key] = value;
    }
  });
}

const DATABASE_URL = process.env.DATABASE_URL;

if (!DATABASE_URL) {
  console.error('❌ Błąd: DATABASE_URL nie jest ustawiony!');
  console.error('');
  console.error('Ustaw zmienną środowiskową DATABASE_URL lub utwórz plik .env.local z:');
  console.error('DATABASE_URL=postgresql://ceramix_user:ceramix_password@localhost:5432/ceramix?sslmode=disable');
  process.exit(1);
}

const pool = new Pool({
  connectionString: DATABASE_URL,
});

async function tableExists(tableName) {
  const client = await pool.connect();
  try {
    const result = await client.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables 
        WHERE table_schema = 'public' 
        AND table_name = $1
      )
    `, [tableName]);
    return result.rows[0].exists;
  } finally {
    client.release();
  }
}

async function executeSqlFile(filePath, ignoreErrors = false) {
  const fullPath = path.join(__dirname, '..', filePath);
  console.log(`📄 Wykonywanie: ${filePath}`);
  
  if (!fs.existsSync(fullPath)) {
    throw new Error(`Plik nie istnieje: ${fullPath}`);
  }
  
  const sql = fs.readFileSync(fullPath, 'utf8');
  const client = await pool.connect();
  
  try {
    await client.query(sql);
    console.log(`✅ Wykonano: ${filePath}`);
  } catch (error) {
    if (ignoreErrors) {
      console.log(`⚠️  Ostrzeżenie podczas wykonywania ${filePath}: ${error.message}`);
    } else {
      console.error(`❌ Błąd podczas wykonywania ${filePath}:`, error.message);
      throw error;
    }
  } finally {
    client.release();
  }
}

async function checkTables() {
  const client = await pool.connect();
  try {
    const result = await client.query(`
      SELECT table_name 
      FROM information_schema.tables 
      WHERE table_schema = 'public' 
      ORDER BY table_name
    `);
    
    console.log('\n📋 Utworzone tabele:');
    result.rows.forEach(row => {
      console.log(`   - ${row.table_name}`);
    });
    
    const requiredTables = ['users', 'dentists', 'appointments', 'invoices', 'payments'];
    const existingTables = result.rows.map(r => r.table_name);
    const missingTables = requiredTables.filter(t => !existingTables.includes(t));
    
    if (missingTables.length > 0) {
      console.log(`\n⚠️  Brakujące tabele: ${missingTables.join(', ')}`);
    } else {
      console.log('\n✅ Wszystkie wymagane tabele istnieją!');
    }
  } finally {
    client.release();
  }
}

async function main() {
  console.log('🔧 Inicjalizacja bazy danych Ceramix\n');
  
  try {
    // Test połączenia
    const client = await pool.connect();
    await client.query('SELECT 1');
    client.release();
    console.log('✅ Połączenie z bazą danych działa\n');
    
    // Sprawdź czy tabela users istnieje
    const usersExists = await tableExists('users');
    
    // Krok 1: Utwórz podstawowe tabele użytkowników (tylko jeśli nie istnieją)
    if (!usersExists) {
      console.log('🔄 Krok 1: Tworzenie tabel użytkowników...');
      await executeSqlFile('lib/db/init-ceramix.sql');
      console.log('');
    } else {
      console.log('ℹ️  Tabele użytkowników już istnieją, pomijam...');
      // Spróbuj uruchomić migracje które mogą dodać brakujące kolumny
      console.log('🔄 Krok 1b: Uruchamianie migracji (dodanie brakujących kolumn)...');
      await executeSqlFile('lib/db/migrations.sql', true);
      console.log('');
    }
    
    // Krok 2: Uruchom migracje (jeśli nie były uruchomione wcześniej)
    if (usersExists) {
      console.log('🔄 Krok 2: Uruchamianie migracji...');
      await executeSqlFile('lib/db/migrations.sql', true);
      console.log('');
    }
    
    // Krok 3: Utwórz schemat Ceramix (pacjenci, dentyści, wizyty, faktury)
    console.log('🔄 Krok 3: Tworzenie schematu Ceramix...');
    await executeSqlFile('lib/db/ceramix-schema.sql', true);
    console.log('');
    
    // Sprawdź tabele
    await checkTables();
    
    console.log('\n✅ Inicjalizacja bazy danych zakończona!');
    
  } catch (error) {
    console.error('\n❌ Błąd podczas inicjalizacji:', error.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

main();

