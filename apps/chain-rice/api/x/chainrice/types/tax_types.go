package types

import (
	"time"

	sdk "github.com/cosmos/cosmos-sdk/types"
)

// TaxModule represents the Polish tax control system
type TaxModule struct {
	ModuleName string
	Version    string
	Enabled    bool
}

// TaxRecord represents a single tax record for Polish tax system
type TaxRecord struct {
	ID              string    `json:"id"`
	TaxpayerID      string    `json:"taxpayer_id"`
	DocumentType    string    `json:"document_type"` // JPK_VAT, JPK_V7M, JPK_FA, etc.
	DocumentNumber  string    `json:"document_number"`
	IssueDate       time.Time `json:"issue_date"`
	SaleDate        time.Time `json:"sale_date"`
	PaymentDate     time.Time `json:"payment_date"`
	GrossAmount     sdk.Coin  `json:"gross_amount"`
	NetAmount       sdk.Coin  `json:"net_amount"`
	TaxAmount       sdk.Coin  `json:"tax_amount"`
	TaxRate         string    `json:"tax_rate"` // 23%, 8%, 5%, 0%, zw
	CounterpartyID  string    `json:"counterparty_id"`
	CounterpartyNIP string    `json:"counterparty_nip"`
	Description     string    `json:"description"`
	Category        string    `json:"category"`
	Status          string    `json:"status"` // pending, approved, rejected
	CreatedAt       time.Time `json:"created_at"`
	UpdatedAt       time.Time `json:"updated_at"`
}

// VATRecord represents VAT-specific tax record
type VATRecord struct {
	*TaxRecord
	VATType          string `json:"vat_type"`           // sprzedaż, zakup, import, export
	VATDeduction     bool   `json:"vat_deduction"`      // czy podlega odliczeniu
	VATReverse       bool   `json:"vat_reverse"`        // czy odwrócone obciążenie
	VATExemption     bool   `json:"vat_exemption"`      // czy zwolnienie z VAT
	VATExemptionCode string `json:"vat_exemption_code"` // kod zwolnienia
}

// JPKRecord represents JPK (Jednolity Plik Kontrolny) record
type JPKRecord struct {
	*VATRecord
	JPKVersion    string    `json:"jpk_version"` // V7M, VAT, FA
	JPKPeriod     string    `json:"jpk_period"`  // YYYY-MM
	JPKSubmission time.Time `json:"jpk_submission"`
	JPKStatus     string    `json:"jpk_status"`    // submitted, accepted, rejected
	JPKReference  string    `json:"jpk_reference"` // numer referencyjny
}

// Taxpayer represents Polish taxpayer entity
type Taxpayer struct {
	ID           string    `json:"id"`
	NIP          string    `json:"nip"`   // Numer Identyfikacji Podatkowej
	REGON        string    `json:"regon"` // Numer REGON
	CompanyName  string    `json:"company_name"`
	Address      string    `json:"address"`
	PostalCode   string    `json:"postal_code"`
	City         string    `json:"city"`
	Country      string    `json:"country"`
	Email        string    `json:"email"`
	Phone        string    `json:"phone"`
	TaxOffice    string    `json:"tax_office"`
	BusinessType string    `json:"business_type"` // JDG, SP, SA, etc.
	IsActive     bool      `json:"is_active"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// TaxCalculation represents tax calculation result
type TaxCalculation struct {
	GrossAmount   sdk.Coin `json:"gross_amount"`
	NetAmount     sdk.Coin `json:"net_amount"`
	TaxAmount     sdk.Coin `json:"tax_amount"`
	TaxRate       string   `json:"tax_rate"`
	TaxType       string   `json:"tax_type"`
	IsDeductible  bool     `json:"is_deductible"`
	IsExempt      bool     `json:"is_exempt"`
	ExemptionCode string   `json:"exemption_code"`
}

// TaxReport represents tax report for specific period
type TaxReport struct {
	ID              string      `json:"id"`
	TaxpayerID      string      `json:"taxpayer_id"`
	ReportType      string      `json:"report_type"` // JPK_VAT, JPK_V7M, PIT, CIT
	Period          string      `json:"period"`      // YYYY-MM
	Year            int         `json:"year"`
	Month           int         `json:"month"`
	Records         []TaxRecord `json:"records"`
	TotalGross      sdk.Coin    `json:"total_gross"`
	TotalNet        sdk.Coin    `json:"total_net"`
	TotalTax        sdk.Coin    `json:"total_tax"`
	Status          string      `json:"status"` // draft, submitted, accepted, rejected
	SubmittedAt     time.Time   `json:"submitted_at"`
	AcceptedAt      time.Time   `json:"accepted_at"`
	RejectedAt      time.Time   `json:"rejected_at"`
	RejectionReason string      `json:"rejection_reason"`
	CreatedAt       time.Time   `json:"created_at"`
	UpdatedAt       time.Time   `json:"updated_at"`
}

// TaxAudit represents tax audit record
type TaxAudit struct {
	ID            string    `json:"id"`
	TaxpayerID    string    `json:"taxpayer_id"`
	AuditType     string    `json:"audit_type"` // kontrolna, sprawozdawcza, wyrywkowa
	AuditPeriod   string    `json:"audit_period"`
	AuditorID     string    `json:"auditor_id"`
	AuditDate     time.Time `json:"audit_date"`
	Findings      string    `json:"findings"`
	Violations    []string  `json:"violations"`
	PenaltyAmount sdk.Coin  `json:"penalty_amount"`
	Status        string    `json:"status"` // ongoing, completed, closed
	CreatedAt     time.Time `json:"created_at"`
	CompletedAt   time.Time `json:"completed_at"`
}

// TaxConfiguration represents tax system configuration
type TaxConfiguration struct {
	ID                  string            `json:"id"`
	TaxRates            map[string]string `json:"tax_rates"`            // "23": "23%", "8": "8%", "5": "5%", "0": "0%", "zw": "zwolniony"
	VATDeductionRules   map[string]bool   `json:"vat_deduction_rules"`  // which categories are deductible
	VATExemptionCodes   map[string]string `json:"vat_exemption_codes"`  // exemption codes and descriptions
	DocumentTypes       []string          `json:"document_types"`       // supported document types
	ReportTypes         []string          `json:"report_types"`         // supported report types
	SubmissionDeadlines map[string]int    `json:"submission_deadlines"` // days to submit after period end
	IsActive            bool              `json:"is_active"`
	LastUpdated         time.Time         `json:"last_updated"`
}

// TaxIntegration represents integration with external tax systems
type TaxIntegration struct {
	ID           string    `json:"id"`
	Name         string    `json:"name"` // KSeF, e-Urząd, etc.
	Type         string    `json:"type"` // api, webhook, file
	Endpoint     string    `json:"endpoint"`
	APIKey       string    `json:"api_key"`
	IsActive     bool      `json:"is_active"`
	LastSync     time.Time `json:"last_sync"`
	SyncStatus   string    `json:"sync_status"` // success, error, pending
	ErrorMessage string    `json:"error_message"`
	CreatedAt    time.Time `json:"created_at"`
	UpdatedAt    time.Time `json:"updated_at"`
}

// TaxCompliance represents compliance status
type TaxCompliance struct {
	TaxpayerID        string    `json:"taxpayer_id"`
	ComplianceScore   int       `json:"compliance_score"` // 0-100
	RiskLevel         string    `json:"risk_level"`       // low, medium, high
	LastSubmission    time.Time `json:"last_submission"`
	NextDeadline      time.Time `json:"next_deadline"`
	OverdueReports    []string  `json:"overdue_reports"`
	PendingAudits     []string  `json:"pending_audits"`
	ComplianceHistory []string  `json:"compliance_history"`
	UpdatedAt         time.Time `json:"updated_at"`
}

// TaxEvent represents tax-related blockchain event
type TaxEvent struct {
	ID          string    `json:"id"`
	TaxpayerID  string    `json:"taxpayer_id"`
	EventType   string    `json:"event_type"` // document_created, report_submitted, audit_started
	EventData   string    `json:"event_data"` // JSON encoded event details
	BlockHeight int64     `json:"block_height"`
	TxHash      string    `json:"tx_hash"`
	Timestamp   time.Time `json:"timestamp"`
}
