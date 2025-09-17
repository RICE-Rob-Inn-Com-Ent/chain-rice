package services

import (
	"database/sql"
	"time"

	"github.com/google/uuid"
)

type InvoiceService struct {
	db *sql.DB
}

func NewInvoiceService(db *sql.DB) *InvoiceService {
	return &InvoiceService{db: db}
}

type Invoice struct {
	ID               string    `json:"id"`
	InvoiceNumber    string    `json:"invoice_number"`
	VendorName       string    `json:"vendor_name"`
	VendorTaxID      string    `json:"vendor_tax_id"`
	VendorAddress    string    `json:"vendor_address"`
	Date             time.Time `json:"date"`
	DueDate          time.Time `json:"due_date"`
	TotalAmount      float64   `json:"total_amount"`
	TaxAmount        float64   `json:"tax_amount"`
	NetAmount        float64   `json:"net_amount"`
	Currency         string    `json:"currency"`
	Description      string    `json:"description"`
	Category         string    `json:"category"`
	Status           string    `json:"status"`
	ReceiptImagePath string    `json:"receipt_image_path"`
	CreatedAt        time.Time `json:"created_at"`
	UpdatedAt        time.Time `json:"updated_at"`
}

type InvoiceItem struct {
	ID          string  `json:"id"`
	Name        string  `json:"name"`
	Description string  `json:"description"`
	Quantity    float64 `json:"quantity"`
	UnitPrice   float64 `json:"unit_price"`
	TotalPrice  float64 `json:"total_price"`
	TaxRate     float64 `json:"tax_rate"`
	TaxAmount   float64 `json:"tax_amount"`
	Category    string  `json:"category"`
}

func (s *InvoiceService) CreateInvoice(invoice *Invoice) (*Invoice, error) {
	// Generate ID if not provided
	if invoice.ID == "" {
		invoice.ID = uuid.New().String()
	}

	// Set timestamps
	now := time.Now()
	if invoice.CreatedAt.IsZero() {
		invoice.CreatedAt = now
	}
	invoice.UpdatedAt = now

	// Insert invoice
	_, err := s.db.Exec(`
		INSERT INTO invoices (id, invoice_number, vendor_name, vendor_tax_id, vendor_address, 
			date, due_date, total_amount, tax_amount, net_amount, currency, description, 
			category, status, receipt_image_path, created_at, updated_at)
		VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
	`, invoice.ID, invoice.InvoiceNumber, invoice.VendorName, invoice.VendorTaxID, invoice.VendorAddress,
		invoice.Date, invoice.DueDate, invoice.TotalAmount, invoice.TaxAmount, invoice.NetAmount,
		invoice.Currency, invoice.Description, invoice.Category, invoice.Status, invoice.ReceiptImagePath,
		invoice.CreatedAt, invoice.UpdatedAt)

	if err != nil {
		return nil, err
	}

	return invoice, nil
}

func (s *InvoiceService) GetInvoice(id string) (*Invoice, error) {
	var invoice Invoice
	err := s.db.QueryRow(`
		SELECT id, invoice_number, vendor_name, vendor_tax_id, vendor_address, 
			date, due_date, total_amount, tax_amount, net_amount, currency, description, 
			category, status, receipt_image_path, created_at, updated_at
		FROM invoices WHERE id = ?
	`, id).Scan(
		&invoice.ID, &invoice.InvoiceNumber, &invoice.VendorName, &invoice.VendorTaxID, &invoice.VendorAddress,
		&invoice.Date, &invoice.DueDate, &invoice.TotalAmount, &invoice.TaxAmount, &invoice.NetAmount,
		&invoice.Currency, &invoice.Description, &invoice.Category, &invoice.Status, &invoice.ReceiptImagePath,
		&invoice.CreatedAt, &invoice.UpdatedAt,
	)

	if err != nil {
		return nil, err
	}

	return &invoice, nil
}

func (s *InvoiceService) ListInvoices(page, pageSize int, status, category string) ([]*Invoice, int, error) {
	offset := (page - 1) * pageSize

	// Build query
	query := "SELECT id, invoice_number, vendor_name, vendor_tax_id, vendor_address, date, due_date, total_amount, tax_amount, net_amount, currency, description, category, status, receipt_image_path, created_at, updated_at FROM invoices WHERE 1=1"
	args := []interface{}{}

	if status != "" {
		query += " AND status = ?"
		args = append(args, status)
	}

	if category != "" {
		query += " AND category = ?"
		args = append(args, category)
	}

	query += " ORDER BY created_at DESC LIMIT ? OFFSET ?"
	args = append(args, pageSize, offset)

	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var invoices []*Invoice
	for rows.Next() {
		var invoice Invoice
		err := rows.Scan(
			&invoice.ID, &invoice.InvoiceNumber, &invoice.VendorName, &invoice.VendorTaxID, &invoice.VendorAddress,
			&invoice.Date, &invoice.DueDate, &invoice.TotalAmount, &invoice.TaxAmount, &invoice.NetAmount,
			&invoice.Currency, &invoice.Description, &invoice.Category, &invoice.Status, &invoice.ReceiptImagePath,
			&invoice.CreatedAt, &invoice.UpdatedAt,
		)
		if err != nil {
			return nil, 0, err
		}
		invoices = append(invoices, &invoice)
	}

	// Get total count
	countQuery := "SELECT COUNT(*) FROM invoices WHERE 1=1"
	countArgs := []interface{}{}

	if status != "" {
		countQuery += " AND status = ?"
		countArgs = append(countArgs, status)
	}

	if category != "" {
		countQuery += " AND category = ?"
		countArgs = append(countArgs, category)
	}

	var total int
	err = s.db.QueryRow(countQuery, countArgs...).Scan(&total)
	if err != nil {
		return nil, 0, err
	}

	return invoices, total, nil
}

func (s *InvoiceService) UpdateInvoice(invoice *Invoice) (*Invoice, error) {
	invoice.UpdatedAt = time.Now()

	_, err := s.db.Exec(`
		UPDATE invoices SET 
			invoice_number = ?, vendor_name = ?, vendor_tax_id = ?, vendor_address = ?,
			date = ?, due_date = ?, total_amount = ?, tax_amount = ?, net_amount = ?,
			currency = ?, description = ?, category = ?, status = ?, receipt_image_path = ?, updated_at = ?
		WHERE id = ?
	`, invoice.InvoiceNumber, invoice.VendorName, invoice.VendorTaxID, invoice.VendorAddress,
		invoice.Date, invoice.DueDate, invoice.TotalAmount, invoice.TaxAmount, invoice.NetAmount,
		invoice.Currency, invoice.Description, invoice.Category, invoice.Status, invoice.ReceiptImagePath,
		invoice.UpdatedAt, invoice.ID)

	if err != nil {
		return nil, err
	}

	return invoice, nil
}

func (s *InvoiceService) DeleteInvoice(id string) error {
	_, err := s.db.Exec("DELETE FROM invoices WHERE id = ?", id)
	return err
}