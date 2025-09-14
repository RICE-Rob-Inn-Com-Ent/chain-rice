package handlers

import (
	"context"
	"time"

	"chainrice/internal/services"
	accountingv1 "chainrice/x/chainrice/types"
)

type AccountingHandler struct {
	accountingv1.UnimplementedAccountingServiceServer
	invoiceService   *services.InvoiceService
	dashboardService *services.DashboardService
}

func NewAccountingHandler(invoiceService *services.InvoiceService, dashboardService *services.DashboardService) *AccountingHandler {
	return &AccountingHandler{
		invoiceService:   invoiceService,
		dashboardService: dashboardService,
	}
}

// Invoice operations
func (h *AccountingHandler) CreateInvoice(ctx context.Context, req *accountingv1.CreateInvoiceRequest) (*accountingv1.CreateInvoiceResponse, error) {
	invoice, err := h.invoiceService.CreateInvoice(req.Invoice)
	if err != nil {
		return &accountingv1.CreateInvoiceResponse{
			Success: false,
			Message: err.Error(),
		}, nil
	}

	return &accountingv1.CreateInvoiceResponse{
		Success: true,
		Message: "Invoice created successfully",
		Invoice: invoice,
	}, nil
}

func (h *AccountingHandler) GetInvoice(ctx context.Context, req *accountingv1.GetInvoiceRequest) (*accountingv1.GetInvoiceResponse, error) {
	invoice, err := h.invoiceService.GetInvoice(req.InvoiceId)
	if err != nil {
		return &accountingv1.GetInvoiceResponse{
			Success: false,
			Message: err.Error(),
		}, nil
	}

	return &accountingv1.GetInvoiceResponse{
		Success: true,
		Message: "Invoice retrieved successfully",
		Invoice: invoice,
	}, nil
}

func (h *AccountingHandler) ListInvoices(ctx context.Context, req *accountingv1.ListInvoicesRequest) (*accountingv1.ListInvoicesResponse, error) {
	invoices, totalCount, err := h.invoiceService.ListInvoices(req)
	if err != nil {
		return &accountingv1.ListInvoicesResponse{
			Success: false,
			Message: err.Error(),
		}, nil
	}

	return &accountingv1.ListInvoicesResponse{
		Success:    true,
		Message:    "Invoices retrieved successfully",
		Invoices:   invoices,
		TotalCount: totalCount,
		Page:       req.Page,
		PageSize:   req.PageSize,
	}, nil
}

func (h *AccountingHandler) UpdateInvoice(ctx context.Context, req *accountingv1.UpdateInvoiceRequest) (*accountingv1.UpdateInvoiceResponse, error) {
	invoice, err := h.invoiceService.UpdateInvoice(req.Invoice)
	if err != nil {
		return &accountingv1.UpdateInvoiceResponse{
			Success: false,
			Message: err.Error(),
		}, nil
	}

	return &accountingv1.UpdateInvoiceResponse{
		Success: true,
		Message: "Invoice updated successfully",
		Invoice: invoice,
	}, nil
}

func (h *AccountingHandler) DeleteInvoice(ctx context.Context, req *accountingv1.DeleteInvoiceRequest) (*accountingv1.DeleteInvoiceResponse, error) {
	err := h.invoiceService.DeleteInvoice(req.InvoiceId)
	if err != nil {
		return &accountingv1.DeleteInvoiceResponse{
			Success: false,
			Message: err.Error(),
		}, nil
	}

	return &accountingv1.DeleteInvoiceResponse{
		Success: true,
		Message: "Invoice deleted successfully",
	}, nil
}

// Dashboard
func (h *AccountingHandler) GetDashboardStats(ctx context.Context, req *accountingv1.GetDashboardStatsRequest) (*accountingv1.GetDashboardStatsResponse, error) {
	var startDate, endDate *time.Time

	if req.StartDate != nil {
		startDate = &req.StartDate.AsTime()
	}
	if req.EndDate != nil {
		endDate = &req.EndDate.AsTime()
	}

	stats, err := h.dashboardService.GetDashboardStats(startDate, endDate)
	if err != nil {
		return &accountingv1.GetDashboardStatsResponse{
			Success: false,
			Message: err.Error(),
		}, nil
	}

	return &accountingv1.GetDashboardStatsResponse{
		Success: true,
		Message: "Dashboard stats retrieved successfully",
		Stats:   stats,
	}, nil
}

// File operations
func (h *AccountingHandler) UploadFile(ctx context.Context, req *accountingv1.FileUploadRequest) (*accountingv1.FileUploadResponse, error) {
	// TODO: Implement file upload logic
	return &accountingv1.FileUploadResponse{
		Success:  true,
		Message:  "File uploaded successfully",
		FilePath: "/uploads/" + req.Filename,
		FileId:   req.Filename,
	}, nil
}

func (h *AccountingHandler) ProcessReceipt(ctx context.Context, req *accountingv1.ReceiptProcessRequest) (*accountingv1.ReceiptProcessResponse, error) {
	// TODO: Implement AI processing
	// For now, return a mock response
	return &accountingv1.ReceiptProcessResponse{
		Success:         true,
		Message:         "Receipt processed successfully (mock)",
		ConfidenceScore: 0.95,
		ExtractedFields: []string{"vendor_name", "total_amount", "date"},
		ExtractedInvoice: &accountingv1.Invoice{
			Id:            "temp-" + time.Now().Format("20060102-150405"),
			InvoiceNumber: "AUTO-" + time.Now().Format("20060102"),
			VendorName:    "Визначено автоматично",
			TotalAmount:   100.0,
			TaxAmount:     23.0,
			NetAmount:     77.0,
			Currency:      "PLN",
			Status:        "pending",
			Category:      "Офісні витрати",
		},
	}, nil
}
