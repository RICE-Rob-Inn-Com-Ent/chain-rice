package main

import (
	"context"
	"log"
)

func main() {
	ctx := context.Background()
	
	log.Println("Chain Rice Accounting Service Starting...")
	
	// Initialize accounting app
	app, err := NewApp(ctx)
	if err != nil {
		log.Fatalf("Failed to initialize accounting: %v", err)
	}
	
	// Start the service
	if err := app.Start(ctx); err != nil {
		log.Fatalf("Failed to start accounting service: %v", err)
	}
}
