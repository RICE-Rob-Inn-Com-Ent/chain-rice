package handlers

import (
	"database/sql"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"github.com/google/uuid"
)

// TaxCalculationRequest represents a tax calculation request
type TaxCalculationRequest struct {
	GrossAmount float64 `json:"gross_amount"`
	TaxRate     float64 `json:"tax_rate"`
	Description string  `json:"description"`
	ContractorID string `json:"contractor_id"`
}

// TaxCalculationResponse represents a tax calculation response
type TaxCalculationResponse struct {
	ID          string  `json:"id"`
	GrossAmount float64 `json:"gross_amount"`
	NetAmount   float64 `json:"net_amount"`
	TaxAmount   float64 `json:"tax_amount"`
	TaxRate     float64 `json:"tax_rate"`
	Description string  `json:"description"`
	CreatedAt   string  `json:"created_at"`
}

// Contractor represents a contractor
type Contractor struct {
	ID          string `json:"id"`
	Name        string `json:"name"`
	NIP         string `json:"nip"`
	REGON       string `json:"regon"`
	Address     string `json:"address"`
	City        string `json:"city"`
	PostalCode  string `json:"postal_code"`
	Phone       string `json:"phone"`
	Email       string `json:"email"`
	Description string `json:"description"`
	CreatedAt   string `json:"created_at"`
}

// CalculateTaxHandler handles tax calculation requests
func CalculateTaxHandler(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var req TaxCalculationRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "Invalid request body", http.StatusBadRequest)
			return
		}

		// Calculate tax
		taxAmount := req.GrossAmount * (req.TaxRate / 100)
		netAmount := req.GrossAmount - taxAmount

		// Generate ID
		id := uuid.New().String()

		// Save to database
		_, err := db.Exec(`
			INSERT INTO tax_calculations (id, contractor_id, gross_amount, net_amount, tax_amount, tax_rate, description)
			VALUES (?, ?, ?, ?, ?, ?, ?)
		`, id, req.ContractorID, req.GrossAmount, netAmount, taxAmount, req.TaxRate, req.Description)

		if err != nil {
			http.Error(w, "Failed to save calculation", http.StatusInternalServerError)
			return
		}

		// Prepare response
		response := TaxCalculationResponse{
			ID:          id,
			GrossAmount: req.GrossAmount,
			NetAmount:   netAmount,
			TaxAmount:   taxAmount,
			TaxRate:     req.TaxRate,
			Description: req.Description,
			CreatedAt:   time.Now().Format(time.RFC3339),
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}
}

// GetContractorsHandler handles getting contractors
func GetContractorsHandler(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		rows, err := db.Query(`
			SELECT id, name, nip, regon, address, city, postal_code, phone, email, description, created_at
			FROM contractors
			ORDER BY created_at DESC
		`)
		if err != nil {
			http.Error(w, "Failed to fetch contractors", http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		var contractors []Contractor
		for rows.Next() {
			var c Contractor
			err := rows.Scan(&c.ID, &c.Name, &c.NIP, &c.REGON, &c.Address, &c.City, &c.PostalCode, &c.Phone, &c.Email, &c.Description, &c.CreatedAt)
			if err != nil {
				http.Error(w, "Failed to scan contractor", http.StatusInternalServerError)
				return
			}
			contractors = append(contractors, c)
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(contractors)
	}
}

// CreateContractorHandler handles creating contractors
func CreateContractorHandler(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		var contractor Contractor
		if err := json.NewDecoder(r.Body).Decode(&contractor); err != nil {
			http.Error(w, "Invalid request body", http.StatusBadRequest)
			return
		}

		// Generate ID
		contractor.ID = uuid.New().String()
		contractor.CreatedAt = time.Now().Format(time.RFC3339)

		// Save to database
		_, err := db.Exec(`
			INSERT INTO contractors (id, name, nip, regon, address, city, postal_code, phone, email, description, created_at)
			VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		`, contractor.ID, contractor.Name, contractor.NIP, contractor.REGON, contractor.Address, contractor.City, contractor.PostalCode, contractor.Phone, contractor.Email, contractor.Description, contractor.CreatedAt)

		if err != nil {
			http.Error(w, "Failed to create contractor", http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(contractor)
	}
}

// GetTaxHistoryHandler handles getting tax calculation history
func GetTaxHistoryHandler(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Get pagination parameters
		pageStr := r.URL.Query().Get("page")
		pageSizeStr := r.URL.Query().Get("page_size")

		page := 1
		pageSize := 10

		if pageStr != "" {
			if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
				page = p
			}
		}

		if pageSizeStr != "" {
			if ps, err := strconv.Atoi(pageSizeStr); err == nil && ps > 0 && ps <= 100 {
				pageSize = ps
			}
		}

		offset := (page - 1) * pageSize

		// Get total count
		var total int
		err := db.QueryRow("SELECT COUNT(*) FROM tax_calculations").Scan(&total)
		if err != nil {
			http.Error(w, "Failed to get total count", http.StatusInternalServerError)
			return
		}

		// Get calculations
		rows, err := db.Query(`
			SELECT id, contractor_id, gross_amount, net_amount, tax_amount, tax_rate, description, created_at
			FROM tax_calculations
			ORDER BY created_at DESC
			LIMIT ? OFFSET ?
		`, pageSize, offset)
		if err != nil {
			http.Error(w, "Failed to fetch calculations", http.StatusInternalServerError)
			return
		}
		defer rows.Close()

		var calculations []TaxCalculationResponse
		for rows.Next() {
			var calc TaxCalculationResponse
			var contractorID string
			err := rows.Scan(&calc.ID, &contractorID, &calc.GrossAmount, &calc.NetAmount, &calc.TaxAmount, &calc.TaxRate, &calc.Description, &calc.CreatedAt)
			if err != nil {
				http.Error(w, "Failed to scan calculation", http.StatusInternalServerError)
				return
			}
			calculations = append(calculations, calc)
		}

		response := map[string]interface{}{
			"calculations": calculations,
			"pagination": map[string]interface{}{
				"page":       page,
				"page_size":  pageSize,
				"total":      total,
				"total_pages": (total + pageSize - 1) / pageSize,
			},
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(response)
	}
}