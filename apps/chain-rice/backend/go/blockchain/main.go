package main

import (
	"context"
	"log"
)

func main() {
	ctx := context.Background()
	
	log.Println("Chain Rice Blockchain Service Starting...")
	
	// Initialize blockchain app
	app, err := NewApp(ctx)
	if err != nil {
		log.Fatalf("Failed to initialize blockchain: %v", err)
	}
	
	// Start the service
	if err := app.Start(ctx); err != nil {
		log.Fatalf("Failed to start blockchain service: %v", err)
	}
}
