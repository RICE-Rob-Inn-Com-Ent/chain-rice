package main

import (
	"fmt"
	"log"
	"os"
)

// Main application entry point
func main() {
	log.Println("Chain Rice Backend Starting...")
	log.Println("This is the main orchestrator for blockchain and accounting services")
	
	// For now, just show available commands
	if len(os.Args) > 1 {
		switch os.Args[1] {
		case "blockchain":
			fmt.Println("Starting blockchain service...")
			fmt.Println("Use: go run ./blockchain to run blockchain module")
		case "accounting":
			fmt.Println("Starting accounting service...")
			fmt.Println("Use: go run ./accounting to run accounting module")
		case "help":
			fmt.Println("Available commands:")
			fmt.Println("  blockchain - Run blockchain service")
			fmt.Println("  accounting - Run accounting service")
			fmt.Println("  help       - Show this help")
		default:
			fmt.Printf("Unknown command: %s\n", os.Args[1])
			os.Exit(1)
		}
		os.Exit(0)
	}
	
	// Main application loop
	log.Println("Main application running...")
	log.Println("Use 'go run main.go help' to see available commands")
	
	// Keep running
	select {}
}
