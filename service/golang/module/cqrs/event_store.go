package cqrs

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	_ "github.com/lib/pq"
)

// CQRSEvent represents a domain event in the event store
type CQRSEvent struct {
	ID            int64                  `json:"id"`
	AggregateID   uuid.UUID              `json:"aggregate_id"`
	AggregateType string                 `json:"aggregate_type"`
	EventType     string                 `json:"event_type"`
	EventData     json.RawMessage        `json:"event_data"`
	Metadata      map[string]interface{} `json:"metadata,omitempty"`
	Version       int                    `json:"version"`
	CreatedAt     time.Time              `json:"created_at"`
}

// CQRSEventStore handles event persistence and retrieval
type CQRSEventStore interface {
	Save(ctx context.Context, event *CQRSEvent) error
	Load(ctx context.Context, aggregateID uuid.UUID) ([]*CQRSEvent, error)
	LoadFromVersion(ctx context.Context, aggregateID uuid.UUID, fromVersion int) ([]*CQRSEvent, error)
	Subscribe(ctx context.Context, eventTypes []string) (<-chan *CQRSEvent, error)
}

// CQRSPostgresEventStore implements EventStore using PostgreSQL
type CQRSPostgresEventStore struct {
	db *sql.DB
}

// CQRSNewPostgresEventStore creates a new PostgreSQL event store
func CQRSNewPostgresEventStore(connectionString string) (*CQRSPostgresEventStore, error) {
	if connectionString == "" {
		return nil, fmt.Errorf("connection string cannot be empty")
	}

	db, err := sql.Open("postgres", connectionString)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	// Set connection pool settings
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(time.Hour)

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := db.PingContext(ctx); err != nil {
		db.Close() // Clean up on failure
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	store := &CQRSPostgresEventStore{db: db}
	if err := store.initSchema(); err != nil {
		db.Close() // Clean up on failure
		return nil, fmt.Errorf("failed to initialize schema: %w", err)
	}

	return store, nil
}

// initSchema creates the events table if it doesn't exist
func (s *CQRSPostgresEventStore) initSchema() error {
	query := `
	CREATE TABLE IF NOT EXISTS events (
		id BIGSERIAL PRIMARY KEY,
		aggregate_id UUID NOT NULL,
		aggregate_type VARCHAR(255) NOT NULL,
		event_type VARCHAR(255) NOT NULL,
		event_data JSONB NOT NULL,
		metadata JSONB,
		version INTEGER NOT NULL,
		created_at TIMESTAMPTZ DEFAULT NOW(),
		UNIQUE(aggregate_id, version)
	);

	CREATE INDEX IF NOT EXISTS idx_events_aggregate_id ON events(aggregate_id);
	CREATE INDEX IF NOT EXISTS idx_events_event_type ON events(event_type);
	CREATE INDEX IF NOT EXISTS idx_events_created_at ON events(created_at);
	`

	_, err := s.db.Exec(query)
	return err
}

// Save persists an event to the store
func (s *CQRSPostgresEventStore) Save(ctx context.Context, event *CQRSEvent) error {
	if ctx == nil {
		return fmt.Errorf("context cannot be nil")
	}

	if event == nil {
		return fmt.Errorf("event cannot be nil")
	}

	// Check context cancellation
	if err := ctx.Err(); err != nil {
		return fmt.Errorf("context cancelled: %w", err)
	}

	// Validate event fields
	if event.AggregateID == (uuid.UUID{}) {
		return fmt.Errorf("aggregate ID cannot be zero")
	}

	if event.AggregateType == "" {
		return fmt.Errorf("aggregate type cannot be empty")
	}

	if event.EventType == "" {
		return fmt.Errorf("event type cannot be empty")
	}

	if len(event.EventData) == 0 {
		return fmt.Errorf("event data cannot be empty")
	}

	if event.Version < 0 {
		return fmt.Errorf("event version cannot be negative")
	}

	metadata, err := json.Marshal(event.Metadata)
	if err != nil {
		return fmt.Errorf("failed to marshal metadata: %w", err)
	}

	query := `
		INSERT INTO events (aggregate_id, aggregate_type, event_type, event_data, metadata, version)
		VALUES ($1, $2, $3, $4, $5, $6)
		RETURNING id, created_at
	`

	err = s.db.QueryRowContext(ctx, query,
		event.AggregateID,
		event.AggregateType,
		event.EventType,
		event.EventData,
		metadata,
		event.Version,
	).Scan(&event.ID, &event.CreatedAt)

	if err != nil {
		return fmt.Errorf("failed to save event: %w", err)
	}

	return nil
}

// Load retrieves all events for an aggregate
func (s *CQRSPostgresEventStore) Load(ctx context.Context, aggregateID uuid.UUID) ([]*CQRSEvent, error) {
	if ctx == nil {
		return nil, fmt.Errorf("context cannot be nil")
	}

	if aggregateID == (uuid.UUID{}) {
		return nil, fmt.Errorf("aggregate ID cannot be zero")
	}

	return s.LoadFromVersion(ctx, aggregateID, 0)
}

// LoadFromVersion retrieves events from a specific version
func (s *CQRSPostgresEventStore) LoadFromVersion(ctx context.Context, aggregateID uuid.UUID, fromVersion int) (events []*CQRSEvent, err error) {
	if ctx == nil {
		return nil, fmt.Errorf("context cannot be nil")
	}

	if aggregateID == (uuid.UUID{}) {
		return nil, fmt.Errorf("aggregate ID cannot be zero")
	}

	if fromVersion < 0 {
		return nil, fmt.Errorf("from version cannot be negative")
	}

	// Check context cancellation
	if err := ctx.Err(); err != nil {
		return nil, fmt.Errorf("context cancelled: %w", err)
	}

	query := `
		SELECT id, aggregate_id, aggregate_type, event_type, event_data, metadata, version, created_at
		FROM events
		WHERE aggregate_id = $1 AND version >= $2
		ORDER BY version ASC
	`

	rows, err := s.db.QueryContext(ctx, query, aggregateID, fromVersion)
	if err != nil {
		return nil, fmt.Errorf("failed to query events: %w", err)
	}

	// Properly handle row closing with error tracking using named return
	defer func() {
		if closeErr := rows.Close(); closeErr != nil {
			// If query succeeded but close failed, preserve the original error if any
			if err == nil {
				err = fmt.Errorf("failed to close rows: %w", closeErr)
			}
		}
	}()

	for rows.Next() {
		// Check context cancellation during iteration
		if err := ctx.Err(); err != nil {
			return nil, fmt.Errorf("context cancelled during iteration: %w", err)
		}

		var event CQRSEvent
		var metadata []byte

		scanErr := rows.Scan(
			&event.ID,
			&event.AggregateID,
			&event.AggregateType,
			&event.EventType,
			&event.EventData,
			&metadata,
			&event.Version,
			&event.CreatedAt,
		)
		if scanErr != nil {
			return nil, fmt.Errorf("failed to scan event: %w", scanErr)
		}

		if len(metadata) > 0 {
			if unmarshalErr := json.Unmarshal(metadata, &event.Metadata); unmarshalErr != nil {
				return nil, fmt.Errorf("failed to unmarshal metadata: %w", unmarshalErr)
			}
		}

		events = append(events, &event)
	}

	if err := rows.Err(); err != nil {
		return nil, fmt.Errorf("error iterating rows: %w", err)
	}

	return events, nil
}

// Subscribe returns a channel that receives new events of specified types
func (s *CQRSPostgresEventStore) Subscribe(ctx context.Context, eventTypes []string) (<-chan *CQRSEvent, error) {
	if ctx == nil {
		return nil, fmt.Errorf("context cannot be nil")
	}

	if len(eventTypes) == 0 {
		return nil, fmt.Errorf("event types cannot be empty")
	}

	// Validate event types
	for _, et := range eventTypes {
		if et == "" {
			return nil, fmt.Errorf("event type cannot be empty")
		}
	}

	// This is a simplified implementation
	// In production, use PostgreSQL LISTEN/NOTIFY or external message broker
	eventChan := make(chan *CQRSEvent, 100)

	go func() {
		defer close(eventChan)
		// Poll for new events (in production, use LISTEN/NOTIFY)
		ticker := time.NewTicker(1 * time.Second)
		defer ticker.Stop()

		var lastID int64 = 0

		for {
			select {
			case <-ctx.Done():
				return
			case <-ticker.C:
				// Check context again before loading events
				if err := ctx.Err(); err != nil {
					return
				}

				events, err := s.loadNewEvents(ctx, eventTypes, lastID)
				if err != nil {
					// Log error but continue polling
					continue
				}

				for _, event := range events {
					if event == nil {
						continue // Skip nil events
					}

					if event.ID > lastID {
						lastID = event.ID
						select {
						case eventChan <- event:
						case <-ctx.Done():
							return
						}
					}
				}
			}
		}
	}()

	return eventChan, nil
}

// loadNewEvents loads events newer than the given ID
func (s *CQRSPostgresEventStore) loadNewEvents(ctx context.Context, eventTypes []string, afterID int64) ([]*CQRSEvent, error) {
	query := `
		SELECT id, aggregate_id, aggregate_type, event_type, event_data, metadata, version, created_at
		FROM events
		WHERE id > $1 AND event_type = ANY($2)
		ORDER BY id ASC
		LIMIT 100
	`

	rows, err := s.db.QueryContext(ctx, query, afterID, eventTypes)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var events []*CQRSEvent
	for rows.Next() {
		var event CQRSEvent
		var metadata []byte

		err := rows.Scan(
			&event.ID,
			&event.AggregateID,
			&event.AggregateType,
			&event.EventType,
			&event.EventData,
			&metadata,
			&event.Version,
			&event.CreatedAt,
		)
		if err != nil {
			return nil, err
		}

		if len(metadata) > 0 {
			if err := json.Unmarshal(metadata, &event.Metadata); err != nil {
				return nil, err
			}
		}

		events = append(events, &event)
	}

	return events, rows.Err()
}

// Close closes the database connection
func (s *CQRSPostgresEventStore) Close() error {
	return s.db.Close()
}
