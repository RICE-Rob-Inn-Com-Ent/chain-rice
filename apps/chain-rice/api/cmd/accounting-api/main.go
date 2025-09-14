package main

import (
	"log"
	"net"
	"net/http"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	_ "github.com/mattn/go-sqlite3"
	"google.golang.org/grpc"
	"google.golang.org/grpc/reflection"

	"chainrice/internal/database"
	"chainrice/internal/handlers"
	"chainrice/internal/services"
	accountingv1 "chainrice/x/chainrice/types"
)

const (
	grpcPort = ":9090"
	httpPort = ":8004"
)

func main() {
	// Initialize database
	db, err := database.InitDB()
	if err != nil {
		log.Fatalf("Failed to initialize database: %v", err)
	}
	defer db.Close()

	// Initialize services
	invoiceService := services.NewInvoiceService(db)
	dashboardService := services.NewDashboardService(db)
	validatorService := services.NewValidatorService(db)

	// Start gRPC server
	go startGRPCServer(invoiceService, dashboardService)

	// Start HTTP server
	startHTTPServer(invoiceService, dashboardService, validatorService)
}

func startGRPCServer(invoiceService *services.InvoiceService, dashboardService *services.DashboardService) {
	lis, err := net.Listen("tcp", grpcPort)
	if err != nil {
		log.Fatalf("Failed to listen on port %s: %v", grpcPort, err)
	}

	s := grpc.NewServer()

	// Register services
	accountingv1.RegisterAccountingServiceServer(s, handlers.NewAccountingHandler(invoiceService, dashboardService))

	// Enable reflection for debugging
	reflection.Register(s)

	log.Printf("gRPC server listening on port %s", grpcPort)
	if err := s.Serve(lis); err != nil {
		log.Fatalf("Failed to serve gRPC: %v", err)
	}
}

func startHTTPServer(invoiceService *services.InvoiceService, dashboardService *services.DashboardService, validatorService *services.ValidatorService) {
	r := gin.Default()

	// CORS configuration
	config := cors.DefaultConfig()
	config.AllowOrigins = []string{"http://localhost:5173", "http://localhost:3000"}
	config.AllowMethods = []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"}
	config.AllowHeaders = []string{"Origin", "Content-Type", "Accept", "Authorization"}
	r.Use(cors.New(config))

	// Health check
	r.GET("/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{"status": "ok", "service": "accounting-api"})
	})

	// API routes
	api := r.Group("/api/v1")
	{
		// Dashboard
		api.GET("/dashboard/stats", handlers.GetDashboardStats(dashboardService))

		// Invoices
		api.GET("/invoices", handlers.ListInvoices(invoiceService))
		api.POST("/invoices", handlers.CreateInvoice(invoiceService))
		api.GET("/invoices/:id", handlers.GetInvoice(invoiceService))
		api.PUT("/invoices/:id", handlers.UpdateInvoice(invoiceService))
		api.DELETE("/invoices/:id", handlers.DeleteInvoice(invoiceService))

		// File upload
		api.POST("/upload", handlers.UploadFile())
		api.POST("/process-receipt", handlers.ProcessReceipt(invoiceService))
	}

	// Setup validator routes
	handlers.SetupValidatorRoutes(r, validatorService)

	log.Printf("HTTP server listening on port %s", httpPort)
	if err := r.Run(httpPort); err != nil {
		log.Fatalf("Failed to start HTTP server: %v", err)
	}
}
