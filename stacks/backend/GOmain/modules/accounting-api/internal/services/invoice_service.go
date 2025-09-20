package services

import (
	"database/sql"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
	"google.golang.org/protobuf/types/known/timestamppb"

	accountingv1 "chainrice/x/chainrice/types"
)

type InvoiceService struct {
	db *sql.DB
}

func NewInvoiceService(db *sql.DB) *InvoiceService {
	return &InvoiceService{db: db}
}

func (s *InvoiceService) CreateInvoice(invoice *accountingv1.Invoice) (*accountingv1.Invoice, error) {
	// Generate ID if not provided
	if invoice.Id == "" {
		invoice.Id = uuid.New().String()
	}

	// Set timestamps
	now := timestamppb.New(time.Now())
	if invoice.CreatedAt == nil {
		invoice.CreatedAt = now
	}
	invoice.UpdatedAt = now

	// Insert invoice
	query := `
		INSERT INTO invoices (
			id, invoice_number, vendor_name, vendor_tax_id, vendor_address,
			date, due_date, total_amount, tax_amount, net_amount,
			currency, description, category, status, receipt_image_path,
			created_at, updated_at
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`

	_, err := s.db.Exec(query,
		invoice.Id, invoice.InvoiceNumber, invoice.VendorName, invoice.VendorTaxId,
		invoice.VendorAddress, invoice.Date.AsTime(), invoice.DueDate.AsTime(),
		invoice.TotalAmount, invoice.TaxAmount, invoice.NetAmount,
		invoice.Currency, invoice.Description, invoice.Category, invoice.Status,
		invoice.ReceiptImagePath, invoice.CreatedAt.AsTime(), invoice.UpdatedAt.AsTime())

	if err != nil {
		return nil, fmt.Errorf("failed to create invoice: %w", err)
	}

	// Insert invoice items
	for _, item := range invoice.Items {
		if err := s.createInvoiceItem(invoice.Id, item); err != nil {
			return nil, err
		}
	}

	return invoice, nil
}

func (s *InvoiceService) createInvoiceItem(invoiceID string, item *accountingv1.InvoiceItem) error {
	if item.Id == "" {
		item.Id = uuid.New().String()
	}

	query := `
		INSERT INTO invoice_items (
			id, invoice_id, name, description, quantity,
			unit_price, total_price, tax_rate, category
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)`

	_, err := s.db.Exec(query,
		item.Id, invoiceID, item.Name, item.Description, item.Quantity,
		item.UnitPrice, item.TotalPrice, item.TaxRate, item.Category)

	return err
}

func (s *InvoiceService) GetInvoice(id string) (*accountingv1.Invoice, error) {
	query := `
		SELECT id, invoice_number, vendor_name, vendor_tax_id, vendor_address,
		       date, due_date, total_amount, tax_amount, net_amount,
		       currency, description, category, status, receipt_image_path,
		       created_at, updated_at
		FROM invoices WHERE id = ?`

	var invoice accountingv1.Invoice
	var date, dueDate, createdAt, updatedAt time.Time

	err := s.db.QueryRow(query, id).Scan(
		&invoice.Id, &invoice.InvoiceNumber, &invoice.VendorName,
		&invoice.VendorTaxId, &invoice.VendorAddress, &date, &dueDate,
		&invoice.TotalAmount, &invoice.TaxAmount, &invoice.NetAmount,
		&invoice.Currency, &invoice.Description, &invoice.Category,
		&invoice.Status, &invoice.ReceiptImagePath, &createdAt, &updatedAt)

	if err != nil {
		if err == sql.ErrNoRows {
			return nil, fmt.Errorf("invoice not found")
		}
		return nil, err
	}

	invoice.Date = timestamppb.New(date)
	invoice.DueDate = timestamppb.New(dueDate)
	invoice.CreatedAt = timestamppb.New(createdAt)
	invoice.UpdatedAt = timestamppb.New(updatedAt)

	// Get invoice items
	items, err := s.getInvoiceItems(id)
	if err != nil {
		return nil, err
	}
	invoice.Items = items

	return &invoice, nil
}

func (s *InvoiceService) getInvoiceItems(invoiceID string) ([]*accountingv1.InvoiceItem, error) {
	query := `
		SELECT id, name, description, quantity, unit_price, total_price, tax_rate, category
		FROM invoice_items WHERE invoice_id = ?`

	rows, err := s.db.Query(query, invoiceID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var items []*accountingv1.InvoiceItem
	for rows.Next() {
		var item accountingv1.InvoiceItem
		err := rows.Scan(
			&item.Id, &item.Name, &item.Description, &item.Quantity,
			&item.UnitPrice, &item.TotalPrice, &item.TaxRate, &item.Category)
		if err != nil {
			return nil, err
		}
		items = append(items, &item)
	}

	return items, nil
}

func (s *InvoiceService) ListInvoices(req *accountingv1.ListInvoicesRequest) ([]*accountingv1.Invoice, int32, error) {
	// Build query with filters
	whereClauses := []string{"1=1"}
	args := []interface{}{}

	if req.Status != "" {
		whereClauses = append(whereClauses, "status = ?")
		args = append(args, req.Status)
	}

	if req.Category != "" {
		whereClauses = append(whereClauses, "category = ?")
		args = append(args, req.Category)
	}

	if req.StartDate != nil {
		whereClauses = append(whereClauses, "date >= ?")
		args = append(args, req.StartDate.AsTime())
	}

	if req.EndDate != nil {
		whereClauses = append(whereClauses, "date <= ?")
		args = append(args, req.EndDate.AsTime())
	}

	whereClause := strings.Join(whereClauses, " AND ")

	// Count total
	countQuery := fmt.Sprintf("SELECT COUNT(*) FROM invoices WHERE %s", whereClause)
	var totalCount int32
	err := s.db.QueryRow(countQuery, args...).Scan(&totalCount)
	if err != nil {
		return nil, 0, err
	}

	// Get invoices with pagination
	offset := (req.Page - 1) * req.PageSize
	query := fmt.Sprintf(`
		SELECT id, invoice_number, vendor_name, vendor_tax_id, vendor_address,
		       date, due_date, total_amount, tax_amount, net_amount,
		       currency, description, category, status, receipt_image_path,
		       created_at, updated_at
		FROM invoices WHERE %s ORDER BY created_at DESC LIMIT ? OFFSET ?`,
		whereClause)

	args = append(args, req.PageSize, offset)
	rows, err := s.db.Query(query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	var invoices []*accountingv1.Invoice
	for rows.Next() {
		var invoice accountingv1.Invoice
		var date, dueDate, createdAt, updatedAt time.Time

		err := rows.Scan(
			&invoice.Id, &invoice.InvoiceNumber, &invoice.VendorName,
			&invoice.VendorTaxId, &invoice.VendorAddress, &date, &dueDate,
			&invoice.TotalAmount, &invoice.TaxAmount, &invoice.NetAmount,
			&invoice.Currency, &invoice.Description, &invoice.Category,
			&invoice.Status, &invoice.ReceiptImagePath, &createdAt, &updatedAt)

		if err != nil {
			return nil, 0, err
		}

		invoice.Date = timestamppb.New(date)
		invoice.DueDate = timestamppb.New(dueDate)
		invoice.CreatedAt = timestamppb.New(createdAt)
		invoice.UpdatedAt = timestamppb.New(updatedAt)

		invoices = append(invoices, &invoice)
	}

	return invoices, totalCount, nil
}

func (s *InvoiceService) UpdateInvoice(invoice *accountingv1.Invoice) (*accountingv1.Invoice, error) {
	invoice.UpdatedAt = timestamppb.New(time.Now())

	query := `
		UPDATE invoices SET
			invoice_number = ?, vendor_name = ?, vendor_tax_id = ?, vendor_address = ?,
			date = ?, due_date = ?, total_amount = ?, tax_amount = ?, net_amount = ?,
			currency = ?, description = ?, category = ?, status = ?, receipt_image_path = ?,
			updated_at = ?
		WHERE id = ?`

	_, err := s.db.Exec(query,
		invoice.InvoiceNumber, invoice.VendorName, invoice.VendorTaxId,
		invoice.VendorAddress, invoice.Date.AsTime(), invoice.DueDate.AsTime(),
		invoice.TotalAmount, invoice.TaxAmount, invoice.NetAmount,
		invoice.Currency, invoice.Description, invoice.Category, invoice.Status,
		invoice.ReceiptImagePath, invoice.UpdatedAt.AsTime(), invoice.Id)

	if err != nil {
		return nil, err
	}

	// Delete existing items and recreate them
	_, err = s.db.Exec("DELETE FROM invoice_items WHERE invoice_id = ?", invoice.Id)
	if err != nil {
		return nil, err
	}

	for _, item := range invoice.Items {
		if err := s.createInvoiceItem(invoice.Id, item); err != nil {
			return nil, err
		}
	}

	return invoice, nil
}

func (s *InvoiceService) DeleteInvoice(id string) error {
	_, err := s.db.Exec("DELETE FROM invoices WHERE id = ?", id)
	return err
}
