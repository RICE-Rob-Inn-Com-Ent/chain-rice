package keeper

import (
	"context"
	"encoding/json"
	"fmt"
	"strconv"
	"time"

	sdkmath "cosmossdk.io/math"
	storetypes "cosmossdk.io/store/types"
	"github.com/cosmos/cosmos-sdk/codec"
	sdk "github.com/cosmos/cosmos-sdk/types"
	"github.com/cosmos/cosmos-sdk/types/query"

	"chainrice/x/chainrice/types"
)

// TaxKeeper handles tax-related operations for Polish tax system
type TaxKeeper struct {
	cdc      codec.BinaryCodec
	storeKey storetypes.StoreKey
	memKey   storetypes.StoreKey
}

// NewTaxKeeper creates a new tax keeper
func NewTaxKeeper(cdc codec.BinaryCodec, storeKey, memKey storetypes.StoreKey) *TaxKeeper {
	return &TaxKeeper{
		cdc:      cdc,
		storeKey: storeKey,
		memKey:   memKey,
	}
}

// StoreKey returns the store key
func (k TaxKeeper) StoreKey() storetypes.StoreKey {
	return k.storeKey
}

// CreateTaxpayer creates a new taxpayer record
func (k TaxKeeper) CreateTaxpayer(ctx context.Context, taxpayer *types.Taxpayer) error {
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)

	// Validate NIP format (10 digits)
	if len(taxpayer.NIP) != 10 {
		return fmt.Errorf("invalid NIP format: must be 10 digits")
	}

	// Check if taxpayer already exists
	key := []byte(fmt.Sprintf("taxpayer:%s", taxpayer.NIP))
	if store.Has(key) {
		return fmt.Errorf("taxpayer with NIP %s already exists", taxpayer.NIP)
	}

	taxpayer.CreatedAt = time.Now()
	taxpayer.UpdatedAt = time.Now()

	bz, err := json.Marshal(taxpayer)
	if err != nil {
		return err
	}

	store.Set(key, bz)

	// Emit event
	sdk.UnwrapSDKContext(ctx).EventManager().EmitEvent(
		sdk.NewEvent(
			"taxpayer_created",
			sdk.NewAttribute("nip", taxpayer.NIP),
			sdk.NewAttribute("company_name", taxpayer.CompanyName),
		),
	)

	return nil
}

// GetTaxpayer retrieves a taxpayer by NIP
func (k TaxKeeper) GetTaxpayer(ctx context.Context, nip string) (*types.Taxpayer, error) {
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)
	key := []byte(fmt.Sprintf("taxpayer:%s", nip))

	if !store.Has(key) {
		return nil, fmt.Errorf("taxpayer with NIP %s not found", nip)
	}

	bz := store.Get(key)
	var taxpayer types.Taxpayer
	if err := json.Unmarshal(bz, &taxpayer); err != nil {
		return nil, err
	}

	return &taxpayer, nil
}

// UpdateTaxpayer updates an existing taxpayer
func (k TaxKeeper) UpdateTaxpayer(ctx context.Context, taxpayer *types.Taxpayer) error {
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)
	key := []byte(fmt.Sprintf("taxpayer:%s", taxpayer.NIP))

	if !store.Has(key) {
		return fmt.Errorf("taxpayer with NIP %s not found", taxpayer.NIP)
	}

	taxpayer.UpdatedAt = time.Now()

	bz, err := json.Marshal(taxpayer)
	if err != nil {
		return err
	}

	store.Set(key, bz)

	// Emit event
	sdk.UnwrapSDKContext(ctx).EventManager().EmitEvent(
		sdk.NewEvent(
			"taxpayer_updated",
			sdk.NewAttribute("nip", taxpayer.NIP),
		),
	)

	return nil
}

// CreateTaxRecord creates a new tax record
func (k TaxKeeper) CreateTaxRecord(ctx context.Context, record *types.TaxRecord) error {
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)

	// Validate taxpayer exists
	_, err := k.GetTaxpayer(ctx, record.TaxpayerID)
	if err != nil {
		return fmt.Errorf("taxpayer validation failed: %w", err)
	}

	// Generate unique ID if not provided
	if record.ID == "" {
		record.ID = fmt.Sprintf("tax_%d_%s", time.Now().Unix(), record.TaxpayerID)
	}

	record.CreatedAt = time.Now()
	record.UpdatedAt = time.Now()
	record.Status = "pending"

	key := []byte(fmt.Sprintf("tax_record:%s", record.ID))

	bz, err := json.Marshal(record)
	if err != nil {
		return err
	}

	store.Set(key, bz)

	// Emit event
	sdk.UnwrapSDKContext(ctx).EventManager().EmitEvent(
		sdk.NewEvent(
			"tax_record_created",
			sdk.NewAttribute("record_id", record.ID),
			sdk.NewAttribute("taxpayer_id", record.TaxpayerID),
			sdk.NewAttribute("document_type", record.DocumentType),
			sdk.NewAttribute("amount", record.GrossAmount.String()),
		),
	)

	return nil
}

// GetTaxRecord retrieves a tax record by ID
func (k TaxKeeper) GetTaxRecord(ctx context.Context, id string) (*types.TaxRecord, error) {
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)
	key := []byte(fmt.Sprintf("tax_record:%s", id))

	if !store.Has(key) {
		return nil, fmt.Errorf("tax record with ID %s not found", id)
	}

	bz := store.Get(key)
	var record types.TaxRecord
	if err := json.Unmarshal(bz, &record); err != nil {
		return nil, err
	}

	return &record, nil
}

// CalculateTax calculates tax for given amount and rate
func (k TaxKeeper) CalculateTax(ctx context.Context, grossAmount sdk.Coin, taxRate string) (*types.TaxCalculation, error) {
	// Parse tax rate
	var rate float64
	var err error

	switch taxRate {
	case "23", "23%":
		rate = 0.23
	case "8", "8%":
		rate = 0.08
	case "5", "5%":
		rate = 0.05
	case "0", "0%":
		rate = 0.0
	case "zw", "zwolniony":
		rate = 0.0
	default:
		rate, err = strconv.ParseFloat(taxRate, 64)
		if err != nil {
			return nil, fmt.Errorf("invalid tax rate: %s", taxRate)
		}
		rate = rate / 100
	}

	gross := grossAmount.Amount
	// Calculate net and tax amounts
	rateDec := sdkmath.LegacyNewDecWithPrec(int64(rate*100), 2)
	net := gross.ToLegacyDec().Quo(sdkmath.LegacyOneDec().Add(rateDec))
	tax := gross.ToLegacyDec().Sub(net)

	netAmount := sdk.NewCoin(grossAmount.Denom, net.TruncateInt())
	taxAmount := sdk.NewCoin(grossAmount.Denom, tax.TruncateInt())

	calculation := &types.TaxCalculation{
		GrossAmount:   grossAmount,
		NetAmount:     netAmount,
		TaxAmount:     taxAmount,
		TaxRate:       taxRate,
		TaxType:       "VAT",
		IsDeductible:  rate > 0 && taxRate != "zw",
		IsExempt:      taxRate == "zw",
		ExemptionCode: "",
	}

	return calculation, nil
}

// CreateTaxReport creates a new tax report
func (k TaxKeeper) CreateTaxReport(ctx context.Context, report *types.TaxReport) error {
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)

	// Validate taxpayer exists
	_, err := k.GetTaxpayer(ctx, report.TaxpayerID)
	if err != nil {
		return fmt.Errorf("taxpayer validation failed: %w", err)
	}

	// Generate unique ID if not provided
	if report.ID == "" {
		report.ID = fmt.Sprintf("report_%s_%s_%d", report.TaxpayerID, report.ReportType, time.Now().Unix())
	}

	report.CreatedAt = time.Now()
	report.UpdatedAt = time.Now()
	report.Status = "draft"

	// Calculate totals from records
	var totalGross, totalNet, totalTax sdkmath.Int
	for _, record := range report.Records {
		totalGross = totalGross.Add(record.GrossAmount.Amount)
		totalNet = totalNet.Add(record.NetAmount.Amount)
		totalTax = totalTax.Add(record.TaxAmount.Amount)
	}

	if len(report.Records) > 0 {
		report.TotalGross = sdk.NewCoin(report.Records[0].GrossAmount.Denom, totalGross)
		report.TotalNet = sdk.NewCoin(report.Records[0].NetAmount.Denom, totalNet)
		report.TotalTax = sdk.NewCoin(report.Records[0].TaxAmount.Denom, totalTax)
	}

	key := []byte(fmt.Sprintf("tax_report:%s", report.ID))

	bz, err := json.Marshal(report)
	if err != nil {
		return err
	}

	store.Set(key, bz)

	// Emit event
	sdk.UnwrapSDKContext(ctx).EventManager().EmitEvent(
		sdk.NewEvent(
			"tax_report_created",
			sdk.NewAttribute("report_id", report.ID),
			sdk.NewAttribute("taxpayer_id", report.TaxpayerID),
			sdk.NewAttribute("report_type", report.ReportType),
			sdk.NewAttribute("period", report.Period),
		),
	)

	return nil
}

// SubmitTaxReport submits a tax report to authorities
func (k TaxKeeper) SubmitTaxReport(ctx context.Context, reportID string) error {
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)
	key := []byte(fmt.Sprintf("tax_report:%s", reportID))

	if !store.Has(key) {
		return fmt.Errorf("tax report with ID %s not found", reportID)
	}

	bz := store.Get(key)
	var report types.TaxReport
	if err := json.Unmarshal(bz, &report); err != nil {
		return err
	}

	if report.Status != "draft" {
		return fmt.Errorf("report is not in draft status")
	}

	report.Status = "submitted"
	report.SubmittedAt = time.Now()
	report.UpdatedAt = time.Now()

	bz, err := json.Marshal(&report)
	if err != nil {
		return err
	}

	store.Set(key, bz)

	// Emit event
	sdk.UnwrapSDKContext(ctx).EventManager().EmitEvent(
		sdk.NewEvent(
			"tax_report_submitted",
			sdk.NewAttribute("report_id", reportID),
			sdk.NewAttribute("taxpayer_id", report.TaxpayerID),
		),
	)

	return nil
}

// GetTaxRecordsByTaxpayer retrieves all tax records for a taxpayer
func (k TaxKeeper) GetTaxRecordsByTaxpayer(ctx context.Context, taxpayerID string, pagination *query.PageRequest) ([]*types.TaxRecord, *query.PageResponse, error) {
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)

	var records []*types.TaxRecord
	iterator := storetypes.KVStorePrefixIterator(store, []byte("tax_record:"))
	defer iterator.Close()

	count := 0
	offset := uint64(0)
	limit := uint64(100) // default limit

	if pagination != nil {
		offset = pagination.Offset
		limit = pagination.Limit
	}

	for ; iterator.Valid(); iterator.Next() {
		if count < int(offset) {
			count++
			continue
		}

		if uint64(len(records)) >= limit {
			break
		}

		var record types.TaxRecord
		if err := json.Unmarshal(iterator.Value(), &record); err != nil {
			continue
		}

		if record.TaxpayerID == taxpayerID {
			records = append(records, &record)
		}
		count++
	}

	total := uint64(count)
	nextKey := iterator.Key()

	pageResponse := &query.PageResponse{
		NextKey: nextKey,
		Total:   total,
	}

	return records, pageResponse, nil
}

// GetTaxReportsByTaxpayer retrieves all tax reports for a taxpayer
func (k TaxKeeper) GetTaxReportsByTaxpayer(ctx context.Context, taxpayerID string, pagination *query.PageRequest) ([]*types.TaxReport, *query.PageResponse, error) {
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)

	var reports []*types.TaxReport
	iterator := storetypes.KVStorePrefixIterator(store, []byte("tax_report:"))
	defer iterator.Close()

	count := 0
	offset := uint64(0)
	limit := uint64(100) // default limit

	if pagination != nil {
		offset = pagination.Offset
		limit = pagination.Limit
	}

	for ; iterator.Valid(); iterator.Next() {
		if count < int(offset) {
			count++
			continue
		}

		if uint64(len(reports)) >= limit {
			break
		}

		var report types.TaxReport
		if err := json.Unmarshal(iterator.Value(), &report); err != nil {
			continue
		}

		if report.TaxpayerID == taxpayerID {
			reports = append(reports, &report)
		}
		count++
	}

	total := uint64(count)
	nextKey := iterator.Key()

	pageResponse := &query.PageResponse{
		NextKey: nextKey,
		Total:   total,
	}

	return reports, pageResponse, nil
}

// CreateTaxAudit creates a new tax audit
func (k TaxKeeper) CreateTaxAudit(ctx context.Context, audit *types.TaxAudit) error {
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)

	// Validate taxpayer exists
	_, err := k.GetTaxpayer(ctx, audit.TaxpayerID)
	if err != nil {
		return fmt.Errorf("taxpayer validation failed: %w", err)
	}

	// Generate unique ID if not provided
	if audit.ID == "" {
		audit.ID = fmt.Sprintf("audit_%s_%d", audit.TaxpayerID, time.Now().Unix())
	}

	audit.CreatedAt = time.Now()
	audit.Status = "ongoing"

	key := []byte(fmt.Sprintf("tax_audit:%s", audit.ID))

	bz, err := json.Marshal(audit)
	if err != nil {
		return err
	}

	store.Set(key, bz)

	// Emit event
	sdk.UnwrapSDKContext(ctx).EventManager().EmitEvent(
		sdk.NewEvent(
			"tax_audit_created",
			sdk.NewAttribute("audit_id", audit.ID),
			sdk.NewAttribute("taxpayer_id", audit.TaxpayerID),
			sdk.NewAttribute("audit_type", audit.AuditType),
		),
	)

	return nil
}

// GetTaxCompliance retrieves compliance status for a taxpayer
func (k TaxKeeper) GetTaxCompliance(ctx context.Context, taxpayerID string) (*types.TaxCompliance, error) {
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)
	key := []byte(fmt.Sprintf("tax_compliance:%s", taxpayerID))

	var compliance types.TaxCompliance
	if store.Has(key) {
		bz := store.Get(key)
		if err := json.Unmarshal(bz, &compliance); err != nil {
			return nil, err
		}
	} else {
		// Create new compliance record
		compliance = types.TaxCompliance{
			TaxpayerID:        taxpayerID,
			ComplianceScore:   100, // Start with perfect score
			RiskLevel:         "low",
			OverdueReports:    []string{},
			PendingAudits:     []string{},
			ComplianceHistory: []string{},
			UpdatedAt:         time.Now(),
		}
	}

	return &compliance, nil
}

// UpdateTaxCompliance updates compliance status for a taxpayer
func (k TaxKeeper) UpdateTaxCompliance(ctx context.Context, compliance *types.TaxCompliance) error {
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)

	compliance.UpdatedAt = time.Now()

	key := []byte(fmt.Sprintf("tax_compliance:%s", compliance.TaxpayerID))

	bz, err := json.Marshal(compliance)
	if err != nil {
		return err
	}

	store.Set(key, bz)

	// Emit event
	sdk.UnwrapSDKContext(ctx).EventManager().EmitEvent(
		sdk.NewEvent(
			"tax_compliance_updated",
			sdk.NewAttribute("taxpayer_id", compliance.TaxpayerID),
			sdk.NewAttribute("compliance_score", fmt.Sprintf("%d", compliance.ComplianceScore)),
			sdk.NewAttribute("risk_level", compliance.RiskLevel),
		),
	)

	return nil
}

// GenerateJPK generates JPK (Jednolity Plik Kontrolny) for a taxpayer
func (k TaxKeeper) GenerateJPK(ctx context.Context, taxpayerID, jpkType, period string) (string, error) {
	// Get taxpayer
	taxpayer, err := k.GetTaxpayer(ctx, taxpayerID)
	if err != nil {
		return "", err
	}

	// Get tax records for the period
	records, _, err := k.GetTaxRecordsByTaxpayer(ctx, taxpayerID, nil)
	if err != nil {
		return "", err
	}

	// Filter records by period
	var periodRecords []*types.TaxRecord
	for _, record := range records {
		if record.IssueDate.Format("2006-01") == period {
			periodRecords = append(periodRecords, record)
		}
	}

	// Generate JPK XML structure
	jpkData := map[string]interface{}{
		"Nagłówek": map[string]interface{}{
			"KodFormularza":     fmt.Sprintf("JPK_%s", jpkType),
			"WariantFormularza": "3",
			"WersjaSchemy":      "1-0E",
			"SystemInfo": map[string]interface{}{
				"SystemNazwa":  "ChainRice Tax System",
				"SystemWersja": "1.0.0",
			},
		},
		"Podmiot1": map[string]interface{}{
			"NIP":        taxpayer.NIP,
			"PelnaNazwa": taxpayer.CompanyName,
			"Adres": map[string]interface{}{
				"Ulica":       taxpayer.Address,
				"NrDomu":      "",
				"NrLokalu":    "",
				"Miejscowosc": taxpayer.City,
				"KodPocztowy": taxpayer.PostalCode,
				"Poczta":      taxpayer.City,
			},
		},
		"Faktury": periodRecords,
	}

	jpkJSON, err := json.MarshalIndent(jpkData, "", "  ")
	if err != nil {
		return "", err
	}

	// Store JPK in blockchain
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)
	jpkID := fmt.Sprintf("jpk_%s_%s_%s", taxpayerID, jpkType, period)
	key := []byte(fmt.Sprintf("jpk:%s", jpkID))
	store.Set(key, jpkJSON)

	// Emit event
	sdk.UnwrapSDKContext(ctx).EventManager().EmitEvent(
		sdk.NewEvent(
			"jpk_generated",
			sdk.NewAttribute("jpk_id", jpkID),
			sdk.NewAttribute("taxpayer_id", taxpayerID),
			sdk.NewAttribute("jpk_type", jpkType),
			sdk.NewAttribute("period", period),
		),
	)

	return jpkID, nil
}

// GetAllTaxpayers retrieves all taxpayers with pagination
func (k TaxKeeper) GetAllTaxpayers(ctx context.Context, pagination *query.PageRequest) ([]*types.Taxpayer, *query.PageResponse, error) {
	store := sdk.UnwrapSDKContext(ctx).KVStore(k.storeKey)

	var taxpayers []*types.Taxpayer
	iterator := storetypes.KVStorePrefixIterator(store, []byte("taxpayer:"))
	defer iterator.Close()

	count := 0
	offset := uint64(0)
	limit := uint64(100) // default limit

	if pagination != nil {
		offset = pagination.Offset
		limit = pagination.Limit
	}

	for ; iterator.Valid(); iterator.Next() {
		if count < int(offset) {
			count++
			continue
		}

		if uint64(len(taxpayers)) >= limit {
			break
		}

		var taxpayer types.Taxpayer
		if err := json.Unmarshal(iterator.Value(), &taxpayer); err != nil {
			continue
		}

		taxpayers = append(taxpayers, &taxpayer)
		count++
	}

	total := uint64(count)
	nextKey := iterator.Key()

	pageResponse := &query.PageResponse{
		NextKey: nextKey,
		Total:   total,
	}

	return taxpayers, pageResponse, nil
}
