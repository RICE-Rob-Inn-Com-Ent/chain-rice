package database

import (
	"database/sql"
	"log"

	_ "github.com/mattn/go-sqlite3"
)

func InitDB() (*sql.DB, error) {
	db, err := sql.Open("sqlite3", "./accounting.db")
	if err != nil {
		return nil, err
	}

	// Create tables
	if err := createTables(db); err != nil {
		return nil, err
	}

	// Seed sample data
	if err := seedData(db); err != nil {
		log.Printf("Warning: Failed to seed data: %v", err)
	}

	return db, nil
}

func createTables(db *sql.DB) error {
	// Invoices table
	invoicesSQL := `
	CREATE TABLE IF NOT EXISTS invoices (
		id TEXT PRIMARY KEY,
		invoice_number TEXT UNIQUE NOT NULL,
		vendor_name TEXT NOT NULL,
		vendor_tax_id TEXT,
		vendor_address TEXT,
		date DATETIME NOT NULL,
		due_date DATETIME,
		total_amount REAL NOT NULL,
		tax_amount REAL NOT NULL,
		net_amount REAL NOT NULL,
		currency TEXT DEFAULT 'PLN',
		description TEXT,
		category TEXT,
		status TEXT DEFAULT 'pending',
		receipt_image_path TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
		updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);`

	// Invoice items table
	itemsSQL := `
	CREATE TABLE IF NOT EXISTS invoice_items (
		id TEXT PRIMARY KEY,
		invoice_id TEXT NOT NULL,
		name TEXT NOT NULL,
		description TEXT,
		quantity INTEGER NOT NULL,
		unit_price REAL NOT NULL,
		total_price REAL NOT NULL,
		tax_rate REAL DEFAULT 0.23,
		category TEXT,
		FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE
	);`

	// Categories table
	categoriesSQL := `
	CREATE TABLE IF NOT EXISTS categories (
		id TEXT PRIMARY KEY,
		name TEXT UNIQUE NOT NULL,
		description TEXT,
		color TEXT DEFAULT '#6366f1'
	);`

	// Vendors table
	vendorsSQL := `
	CREATE TABLE IF NOT EXISTS vendors (
		id TEXT PRIMARY KEY,
		name TEXT UNIQUE NOT NULL,
		tax_id TEXT UNIQUE,
		address TEXT,
		contact_email TEXT,
		contact_phone TEXT,
		created_at DATETIME DEFAULT CURRENT_TIMESTAMP
	);`

	if _, err := db.Exec(invoicesSQL); err != nil {
		return err
	}
	if _, err := db.Exec(itemsSQL); err != nil {
		return err
	}
	if _, err := db.Exec(categoriesSQL); err != nil {
		return err
	}
	if _, err := db.Exec(vendorsSQL); err != nil {
		return err
	}

	return nil
}

func seedData(db *sql.DB) error {
	// Insert sample categories
	categories := []struct {
		id, name, description, color string
	}{
		{"cat-1", "Офісні витрати", "Канцелярські товари, папір, тощо", "#3b82f6"},
		{"cat-2", "Програмне забезпечення", "Ліцензії, підписки", "#8b5cf6"},
		{"cat-3", "Обладнання", "Комп'ютери, принтери, тощо", "#10b981"},
		{"cat-4", "Маркетинг", "Реклама, поліграфія", "#f59e0b"},
		{"cat-5", "Подорожі", "Транспорт, готелі", "#ef4444"},
		{"cat-6", "Харчування", "Бізнес ланчі, кава", "#f97316"},
	}

	for _, cat := range categories {
		_, err := db.Exec(`
			INSERT OR IGNORE INTO categories (id, name, description, color) 
			VALUES (?, ?, ?, ?)`,
			cat.id, cat.name, cat.description, cat.color)
		if err != nil {
			return err
		}
	}

	// Insert sample vendors
	vendors := []struct {
		id, name, tax_id, address string
	}{
		{"vendor-1", "Канцелярія Плюс", "1234567890", "вул. Головна 123, Київ"},
		{"vendor-2", "IT Solutions", "0987654321", "пр. Перемоги 456, Львів"},
		{"vendor-3", "Офісні Меблі", "1122334455", "вул. Шевченка 789, Харків"},
	}

	for _, vendor := range vendors {
		_, err := db.Exec(`
			INSERT OR IGNORE INTO vendors (id, name, tax_id, address) 
			VALUES (?, ?, ?, ?)`,
			vendor.id, vendor.name, vendor.tax_id, vendor.address)
		if err != nil {
			return err
		}
	}

	return nil
}
