package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
)

func main() {
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		fmt.Fprint(w, "{\"status\":\"ok\",\"service\":\"ceramix-database\"}")
	})
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}
	log.Printf("Ceramix database service listening on :%s", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}














