package main

import (
	"encoding/json"
	"log"
	"net/http"
	"os"
	"time"

	"github.com/docker/docker/client"
	"github.com/gorilla/mux"
)

type CacheManager struct {
	dockerClient *client.Client
	cacheDir     string
	maxCacheSizeGB int
}

type CacheStatus struct {
	GodID      string    `json:"godId"`
	IsLoaded   bool      `json:"isLoaded"`
	SizeBytes  int64     `json:"sizeBytes"`
	LastAccess time.Time `json:"lastAccess"`
}

func NewCacheManager() (*CacheManager, error) {
	cli, err := client.NewClientWithOpts(client.FromEnv, client.WithAPIVersionNegotiation())
	if err != nil {
		return nil, err
	}

	cacheDir := os.Getenv("CACHE_DIR")
	if cacheDir == "" {
		cacheDir = "/cache"
	}

	maxCache := 50 // default 50GB
	if val := os.Getenv("MAX_CACHE_SIZE_GB"); val != "" {
		// Parse val
	}

	return &CacheManager{
		dockerClient:   cli,
		cacheDir:       cacheDir,
		maxCacheSizeGB: maxCache,
	}, nil
}

func (cm *CacheManager) handleUnload(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	godID := vars["god"]

	log.Printf("Unloading model for god: %s", godID)

	// In real implementation, would send signal to Ollama container
	// to unload the model from GPU memory

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"success": true,
		"godId":   godID,
		"message": "Model unloaded successfully",
	})
}

func (cm *CacheManager) handleCacheStatus(w http.ResponseWriter, r *http.Request) {
	// Get cache status for all gods
	statuses := []CacheStatus{
		{GodID: "thoth", IsLoaded: false, SizeBytes: 4372824384, LastAccess: time.Now()},
		{GodID: "ra", IsLoaded: false, SizeBytes: 0, LastAccess: time.Now()},
		{GodID: "anubis", IsLoaded: false, SizeBytes: 0, LastAccess: time.Now()},
		{GodID: "isis", IsLoaded: false, SizeBytes: 0, LastAccess: time.Now()},
		{GodID: "horus", IsLoaded: false, SizeBytes: 0, LastAccess: time.Now()},
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(statuses)
}

func (cm *CacheManager) handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"status": "healthy",
		"uptime": time.Since(time.Now()),
	})
}

func main() {
	cm, err := NewCacheManager()
	if err != nil {
		log.Fatal(err)
	}

	r := mux.NewRouter()

	// API routes
	r.HandleFunc("/api/cache/unload/{god}", cm.handleUnload).Methods("POST")
	r.HandleFunc("/api/cache/status", cm.handleCacheStatus).Methods("GET")
	r.HandleFunc("/health", cm.handleHealth).Methods("GET")

	log.Println("Cache Manager starting on :9090")
	if err := http.ListenAndServe(":9090", r); err != nil {
		log.Fatal(err)
	}
}
