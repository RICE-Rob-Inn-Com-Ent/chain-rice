package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/chainrice/rice/backend/module"

	"github.com/google/uuid"
)

func main() {
	// Database connection - use environment variables dynamically
	// Supports: DATABASE_URL or individual POSTGRES_* env vars
	dbURL := buildDatabaseURL()
	if dbURL == "" {
		log.Fatal("DATABASE_URL or POSTGRES_* environment variables must be set")
	}

	eventStore, err := module.CQRSNewPostgresEventStore(dbURL)
	if err != nil {
		log.Fatalf("Failed to create event store: %v", err)
	}
	defer eventStore.Close()

	// Initialize buses
	commandBus := module.CQRSNewCommandBus()
	queryBus := module.CQRSNewQueryBus()

	// Register handlers
	registerHandlers(commandBus, queryBus, eventStore)

	// HTTP Server
	mux := http.NewServeMux()

	// Command endpoints
	mux.HandleFunc("/api/commands/create-user", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var cmd module.CQRSCreateUserCommand
		if err := json.NewDecoder(r.Body).Decode(&cmd); err != nil {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}

		if err := commandBus.Execute(r.Context(), cmd); err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.WriteHeader(http.StatusCreated)
		json.NewEncoder(w).Encode(map[string]string{"status": "created"})
	})

	// Query endpoints
	mux.HandleFunc("/api/queries/user/", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodGet {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		userID := r.URL.Path[len("/api/queries/user/"):]
		query := module.CQRSGetUserByIDQuery{UserID: userID}

		result, err := queryBus.Execute(r.Context(), query)
		if err != nil {
			http.Error(w, err.Error(), http.StatusInternalServerError)
			return
		}

		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(result)
	})

	// Health check
	mux.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		json.NewEncoder(w).Encode(map[string]string{"status": "healthy"})
	})

	server := &http.Server{
		Addr:    ":8080",
		Handler: mux,
	}

	// Graceful shutdown
	go func() {
		log.Println("CQRS Server starting on :8080")
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server error: %v", err)
		}
	}()

	// Wait for interrupt signal
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Println("Shutting down server...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server forced to shutdown: %v", err)
	}

	log.Println("Server exited")
}

func registerHandlers(cmdBus *module.CQRSCommandBus, queryBus *module.CQRSQueryBus, eventStore module.CQRSEventStore) {
	// Register command handlers
	cmdBus.Register("CreateUser", &CreateUserHandler{eventStore: eventStore})
	cmdBus.Register("UpdateUser", &UpdateUserHandler{eventStore: eventStore})
	cmdBus.Register("DeleteUser", &DeleteUserHandler{eventStore: eventStore})

	// Register query handlers
	queryBus.Register("GetUserByID", &GetUserByIDHandler{eventStore: eventStore})
	queryBus.Register("ListUsers", &ListUsersHandler{eventStore: eventStore})
}

// Command Handlers

type CreateUserHandler struct {
	eventStore module.CQRSEventStore
}

func (h *CreateUserHandler) Handle(ctx context.Context, cmd module.CQRSCommand) error {
	createCmd := cmd.(module.CQRSCreateUserCommand)

	// Create event
	evt := module.CQRSUserCreatedEvent{
		CQRSBaseEvent: module.CQRSBaseEvent{Timestamp: time.Now()},
		UserID:        createCmd.UserID,
		Email:         createCmd.Email,
		Name:          createCmd.Name,
	}

	eventData, err := json.Marshal(evt)
	if err != nil {
		return err
	}

	aggregateID, _ := uuid.Parse(createCmd.UserID)
	storeEvent := &module.CQRSEvent{
		AggregateID:   aggregateID,
		AggregateType: "User",
		EventType:     evt.EventType(),
		EventData:     eventData,
		Version:       1,
		Metadata: map[string]interface{}{
			"command": "CreateUser",
		},
	}

	return h.eventStore.Save(ctx, storeEvent)
}

type UpdateUserHandler struct {
	eventStore module.CQRSEventStore
}

func (h *UpdateUserHandler) Handle(ctx context.Context, cmd module.CQRSCommand) error {
	updateCmd := cmd.(module.CQRSUpdateUserCommand)

	evt := module.CQRSUserUpdatedEvent{
		CQRSBaseEvent: module.CQRSBaseEvent{Timestamp: time.Now()},
		UserID:        updateCmd.UserID,
		Email:         updateCmd.Email,
		Name:          updateCmd.Name,
	}

	eventData, err := json.Marshal(evt)
	if err != nil {
		return err
	}

	aggregateID, _ := uuid.Parse(updateCmd.UserID)

	// Load existing events to get version
	existingEvents, err := h.eventStore.Load(ctx, aggregateID)
	if err != nil {
		return err
	}

	version := len(existingEvents) + 1

	storeEvent := &module.CQRSEvent{
		AggregateID:   aggregateID,
		AggregateType: "User",
		EventType:     evt.EventType(),
		EventData:     eventData,
		Version:       version,
	}

	return h.eventStore.Save(ctx, storeEvent)
}

type DeleteUserHandler struct {
	eventStore module.CQRSEventStore
}

func (h *DeleteUserHandler) Handle(ctx context.Context, cmd module.CQRSCommand) error {
	deleteCmd := cmd.(module.CQRSDeleteUserCommand)

	evt := module.CQRSUserDeletedEvent{
		CQRSBaseEvent: module.CQRSBaseEvent{Timestamp: time.Now()},
		UserID:        deleteCmd.UserID,
	}

	eventData, err := json.Marshal(evt)
	if err != nil {
		return err
	}

	aggregateID, _ := uuid.Parse(deleteCmd.UserID)
	existingEvents, err := h.eventStore.Load(ctx, aggregateID)
	if err != nil {
		return err
	}

	version := len(existingEvents) + 1

	storeEvent := &module.CQRSEvent{
		AggregateID:   aggregateID,
		AggregateType: "User",
		EventType:     evt.EventType(),
		EventData:     eventData,
		Version:       version,
	}

	return h.eventStore.Save(ctx, storeEvent)
}

// Query Handlers

type GetUserByIDHandler struct {
	eventStore module.CQRSEventStore
}

func (h *GetUserByIDHandler) Handle(ctx context.Context, q module.CQRSQuery) (interface{}, error) {
	getQuery := q.(module.CQRSGetUserByIDQuery)
	aggregateID, err := uuid.Parse(getQuery.UserID)
	if err != nil {
		return nil, err
	}

	events, err := h.eventStore.Load(ctx, aggregateID)
	if err != nil {
		return nil, err
	}

	// Rebuild user state from events
	user := map[string]interface{}{
		"user_id": getQuery.UserID,
		"events":  len(events),
	}

	for _, event := range events {
		switch event.EventType {
		case "UserCreated":
			var e module.CQRSUserCreatedEvent
			json.Unmarshal(event.EventData, &e)
			user["email"] = e.Email
			user["name"] = e.Name
		case "UserUpdated":
			var e module.CQRSUserUpdatedEvent
			json.Unmarshal(event.EventData, &e)
			user["email"] = e.Email
			user["name"] = e.Name
		case "UserDeleted":
			user["deleted"] = true
		}
	}

	return user, nil
}

type ListUsersHandler struct {
	eventStore module.CQRSEventStore
}

func (h *ListUsersHandler) Handle(ctx context.Context, q module.CQRSQuery) (interface{}, error) {
	// This is simplified - in production use a read model/projection
	return map[string]interface{}{
		"message": "List users - implement read model projection",
	}, nil
}

func getEnv(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
}

// buildDatabaseURL constructs PostgreSQL connection URL from environment variables
// Priority: DATABASE_URL > individual POSTGRES_* variables
func buildDatabaseURL() string {
	// Check if DATABASE_URL is set (takes precedence)
	if dbURL := os.Getenv("DATABASE_URL"); dbURL != "" {
		return dbURL
	}

	// Build from individual environment variables
	host := getEnv("POSTGRES_HOST", "localhost")
	port := getEnv("POSTGRES_PORT", "5432")
	user := getEnv("POSTGRES_USER", "postgres")
	password := getEnv("POSTGRES_PASSWORD", "postgres")
	database := getEnv("POSTGRES_DB", "postgres")
	sslMode := getEnv("POSTGRES_SSLMODE", "disable")

	// Build connection string
	return fmt.Sprintf("postgresql://%s:%s@%s:%s/%s?sslmode=%s",
		user, password, host, port, database, sslMode)
}
