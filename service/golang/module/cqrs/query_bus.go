package cqrs

import (
	"context"
	"fmt"
	"sync"
)

// CQRSQuery represents a query in the system
type CQRSQuery interface {
	QueryName() string
}

// CQRSQueryHandler handles a specific query type
type CQRSQueryHandler interface {
	Handle(ctx context.Context, query CQRSQuery) (interface{}, error)
}

// CQRSQueryBus routes queries to their handlers
type CQRSQueryBus struct {
	handlers map[string]CQRSQueryHandler
	mu       sync.RWMutex
}

// NewQueryBus creates a new query bus
func NewQueryBus() *CQRSQueryBus {
	return &CQRSQueryBus{
		handlers: make(map[string]CQRSQueryHandler),
	}
}

// CQRSNewQueryBus is deprecated, use NewQueryBus instead
// Deprecated: Use NewQueryBus for consistency
func CQRSNewQueryBus() *CQRSQueryBus {
	return NewQueryBus()
}

// Register registers a handler for a query type
func (qb *CQRSQueryBus) Register(queryName string, handler CQRSQueryHandler) {
	qb.mu.Lock()
	defer qb.mu.Unlock()
	qb.handlers[queryName] = handler
}

// Execute executes a query
func (qb *CQRSQueryBus) Execute(ctx context.Context, query CQRSQuery) (interface{}, error) {
	if query == nil {
		return nil, fmt.Errorf("query cannot be nil")
	}

	if ctx == nil {
		return nil, fmt.Errorf("context cannot be nil")
	}

	// Check context cancellation
	if err := ctx.Err(); err != nil {
		return nil, fmt.Errorf("context cancelled: %w", err)
	}

	queryName := query.QueryName()
	if queryName == "" {
		return nil, fmt.Errorf("query name cannot be empty")
	}

	qb.mu.RLock()
	handler, exists := qb.handlers[queryName]
	qb.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("no handler registered for query: %s", queryName)
	}

	if handler == nil {
		return nil, fmt.Errorf("handler for query %s is nil", queryName)
	}

	return handler.Handle(ctx, query)
}

// Example Queries

// CQRSGetUserByIDQuery retrieves a user by ID
type CQRSGetUserByIDQuery struct {
	UserID string
}

func (q CQRSGetUserByIDQuery) QueryName() string {
	return "GetUserByID"
}

// CQRSListUsersQuery lists all users
type CQRSListUsersQuery struct {
	Limit  int
	Offset int
}

func (q CQRSListUsersQuery) QueryName() string {
	return "ListUsers"
}

// CQRSSearchUsersQuery searches users by criteria
type CQRSSearchUsersQuery struct {
	Email string
	Name  string
}

func (q CQRSSearchUsersQuery) QueryName() string {
	return "SearchUsers"
}
