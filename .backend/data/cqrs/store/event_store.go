package store

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"time"

	"github.com/google/uuid"
	_ "github.com/lib/pq"
)

// Event represents a domain event in the event store
type Event struct {
	ID            int64                  `json:"id"`
	AggregateID   uuid.UUID              `json:"aggregate_id"`
	AggregateType string                 `json:"aggregate_type"`
	EventType     string                 `json:"event_type"`
	EventData     json.RawMessage        `json:"event_data"`
	Metadata      map[string]interface{} `json:"metadata,omitempty"`
	Version       int                    `json:"version"`
	CreatedAt     time.Time              `json:"created_at"`
}

// EventStore handles event persistence and retrieval
type EventStore interface {
	Save(ctx context.Context, event *Event) error
	Load(ctx context.Context, aggregateID uuid.UUID) ([]*Event, error)
	LoadFromVersion(ctx context.Context, aggregateID uuid.UUID, fromVersion int) ([]*Event, error)
	Subscribe(ctx context.Context, eventTypes []string) (<-chan *Event, error)
}

// PostgresEventStore implements EventStore using PostgreSQL
type PostgresEventStore struct {
	db *sql.DB
}

// NewPostgresEventStore creates a new PostgreSQL event store
func NewPostgresEventStore(connectionString string) (*PostgresEventStore, error) {
	db, err := sql.Open("postgres", connectionString)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to database: %w", err)
	}

	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	store := &PostgresEventStore{db: db}
	if err := store.initSchema(); err != nil {
		return nil, fmt.Errorf("failed to initialize schema: %w", err)
	}

	return store, nil
}

// initSchema creates the events table if it doesn't exist
func (s *PostgresEventStore) initSchema() error {
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
func (s *PostgresEventStore) Save(ctx context.Context, event *Event) error {
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
func (s *PostgresEventStore) Load(ctx context.Context, aggregateID uuid.UUID) ([]*Event, error) {
	return s.LoadFromVersion(ctx, aggregateID, 0)
}

// LoadFromVersion retrieves events from a specific version
func (s *PostgresEventStore) LoadFromVersion(ctx context.Context, aggregateID uuid.UUID, fromVersion int) ([]*Event, error) {
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
	defer rows.Close()

	var events []*Event
	for rows.Next() {
		var event Event
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
			return nil, fmt.Errorf("failed to scan event: %w", err)
		}

		if len(metadata) > 0 {
			if err := json.Unmarshal(metadata, &event.Metadata); err != nil {
				return nil, fmt.Errorf("failed to unmarshal metadata: %w", err)
			}
		}

		events = append(events, &event)
	}

	return events, rows.Err()
}

// Subscribe returns a channel that receives new events of specified types
func (s *PostgresEventStore) Subscribe(ctx context.Context, eventTypes []string) (<-chan *Event, error) {
	// This is a simplified implementation
	// In production, use PostgreSQL LISTEN/NOTIFY or external message broker
	eventChan := make(chan *Event, 100)

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
				events, err := s.loadNewEvents(ctx, eventTypes, lastID)
				if err != nil {
					continue
				}

				for _, event := range events {
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
func (s *PostgresEventStore) loadNewEvents(ctx context.Context, eventTypes []string, afterID int64) ([]*Event, error) {
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

	var events []*Event
	for rows.Next() {
		var event Event
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
func (s *PostgresEventStore) Close() error {
	return s.db.Close()
}
