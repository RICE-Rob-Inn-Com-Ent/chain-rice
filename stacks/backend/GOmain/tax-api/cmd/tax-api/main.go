package main

import (
	"log"
	"net/http"
	"os"

	"github.com/gorilla/mux"
	"github.com/rs/cors"
	"chainrice/shared"
	"chainrice/shared/handlers"
)

func main() {
	// Initialize database
	db, err := shared.InitDB()
	if err != nil {
		log.Fatal("Failed to initialize database:", err)
	}
	defer db.Close()

	// Create router
	router := mux.NewRouter()

	// Add CORS middleware
	c := cors.New(cors.Options{
		AllowedOrigins: []string{
			"http://localhost:5173",
			"http://localhost:3000",
		},
		AllowedMethods: []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowedHeaders: []string{"*"},
	})

	// Health check endpoint
	router.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"service":"tax-api","status":"healthy"}`))
	}).Methods("GET")

	// API routes
	api := router.PathPrefix("/api/v1").Subrouter()
	
	// Tax calculation endpoints
	api.HandleFunc("/calculate", handlers.CalculateTaxHandler(db)).Methods("POST")
	api.HandleFunc("/contractors", handlers.GetContractorsHandler(db)).Methods("GET")
	api.HandleFunc("/contractors", handlers.CreateContractorHandler(db)).Methods("POST")
	api.HandleFunc("/history", handlers.GetTaxHistoryHandler(db)).Methods("GET")

	// Get port from environment or use default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8003"
	}

	log.Printf("Tax API server starting on port %s", port)
	log.Fatal(http.ListenAndServe(":"+port, c.Handler(router)))
}