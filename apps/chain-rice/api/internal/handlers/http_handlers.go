package handlers

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"
	"google.golang.org/protobuf/types/known/timestamppb"

	accountingv1 "chainrice/x/chainrice/types"
	"chainrice/internal/services"
)

func GetDashboardStats(dashboardService *services.DashboardService) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Parse date parameters
		var startDate, endDate *time.Time
		
		if startStr := c.Query("start_date"); startStr != "" {
			if parsed, err := time.Parse("2006-01-02", startStr); err == nil {
				startDate = &parsed
			}
		}
		
		if endStr := c.Query("end_date"); endStr != "" {
			if parsed, err := time.Parse("2006-01-02", endStr); err == nil {
				endDate = &parsed
			}
		}

		stats, err := dashboardService.GetDashboardStats(startDate, endDate)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    stats,
		})
	}
}

func ListInvoices(invoiceService *services.InvoiceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		// Parse query parameters
		page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
		pageSize, _ := strconv.Atoi(c.DefaultQuery("page_size", "10"))
		status := c.Query("status")
		category := c.Query("category")
		
		var startDate, endDate *time.Time
		
		if startStr := c.Query("start_date"); startStr != "" {
			if parsed, err := time.Parse("2006-01-02", startStr); err == nil {
				startDate = &parsed
			}
		}
		
		if endStr := c.Query("end_date"); endStr != "" {
			if parsed, err := time.Parse("2006-01-02", endStr); err == nil {
				endDate = &parsed
			}
		}

		req := &accountingv1.ListInvoicesRequest{
			Page:      int32(page),
			PageSize:  int32(pageSize),
			Status:    status,
			Category:  category,
			StartDate: timestamppb.New(*startDate) if startDate != nil else nil,
			EndDate:   timestamppb.New(*endDate) if endDate != nil else nil,
		}

		invoices, totalCount, err := invoiceService.ListInvoices(req)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data": gin.H{
				"invoices":    invoices,
				"total_count": totalCount,
				"page":        page,
				"page_size":   pageSize,
			},
		})
	}
}

func CreateInvoice(invoiceService *services.InvoiceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var invoice accountingv1.Invoice
		if err := c.ShouldBindJSON(&invoice); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		createdInvoice, err := invoiceService.CreateInvoice(&invoice)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusCreated, gin.H{
			"success": true,
			"data":    createdInvoice,
		})
	}
}

func GetInvoice(invoiceService *services.InvoiceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invoice ID is required"})
			return
		}

		invoice, err := invoiceService.GetInvoice(id)
		if err != nil {
			c.JSON(http.StatusNotFound, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    invoice,
		})
	}
}

func UpdateInvoice(invoiceService *services.InvoiceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invoice ID is required"})
			return
		}

		var invoice accountingv1.Invoice
		if err := c.ShouldBindJSON(&invoice); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		invoice.Id = id // Ensure ID matches URL parameter

		updatedInvoice, err := invoiceService.UpdateInvoice(&invoice)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    updatedInvoice,
		})
	}
}

func DeleteInvoice(invoiceService *services.InvoiceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		id := c.Param("id")
		if id == "" {
			c.JSON(http.StatusBadRequest, gin.H{"error": "invoice ID is required"})
			return
		}

		err := invoiceService.DeleteInvoice(id)
		if err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": err.Error()})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"message": "Invoice deleted successfully",
		})
	}
}

func UploadFile() gin.HandlerFunc {
	return func(c *gin.Context) {
		file, err := c.FormFile("file")
		if err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": "No file uploaded"})
			return
		}

		// Create uploads directory if it doesn't exist
		// Save file
		filename := "uploads/" + file.Filename
		if err := c.SaveUploadedFile(file, filename); err != nil {
			c.JSON(http.StatusInternalServerError, gin.H{"error": "Failed to save file"})
			return
		}

		c.JSON(http.StatusOK, gin.H{
			"success":  true,
			"message":  "File uploaded successfully",
			"file_path": filename,
			"file_id":   file.Filename,
		})
	}
}

func ProcessReceipt(invoiceService *services.InvoiceService) gin.HandlerFunc {
	return func(c *gin.Context) {
		var req accountingv1.ReceiptProcessRequest
		if err := c.ShouldBindJSON(&req); err != nil {
			c.JSON(http.StatusBadRequest, gin.H{"error": err.Error()})
			return
		}

		// TODO: Implement AI processing
		// For now, return a mock response
		response := &accountingv1.ReceiptProcessResponse{
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
		}

		c.JSON(http.StatusOK, gin.H{
			"success": true,
			"data":    response,
		})
	}
}
