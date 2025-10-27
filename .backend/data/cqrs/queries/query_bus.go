package queries

import (
	"context"
	"fmt"
	"sync"
)

// Query represents a query in the system
type Query interface {
	QueryName() string
}

// QueryHandler handles a specific query type
type QueryHandler interface {
	Handle(ctx context.Context, query Query) (interface{}, error)
}

// QueryBus routes queries to their handlers
type QueryBus struct {
	handlers map[string]QueryHandler
	mu       sync.RWMutex
}

// NewQueryBus creates a new query bus
func NewQueryBus() *QueryBus {
	return &QueryBus{
		handlers: make(map[string]QueryHandler),
	}
}

// Register registers a handler for a query type
func (qb *QueryBus) Register(queryName string, handler QueryHandler) {
	qb.mu.Lock()
	defer qb.mu.Unlock()
	qb.handlers[queryName] = handler
}

// Execute executes a query
func (qb *QueryBus) Execute(ctx context.Context, query Query) (interface{}, error) {
	qb.mu.RLock()
	handler, exists := qb.handlers[query.QueryName()]
	qb.mu.RUnlock()

	if !exists {
		return nil, fmt.Errorf("no handler registered for query: %s", query.QueryName())
	}

	return handler.Handle(ctx, query)
}

// Example Queries

// GetUserByIDQuery retrieves a user by ID
type GetUserByIDQuery struct {
	UserID string
}

func (q GetUserByIDQuery) QueryName() string {
	return "GetUserByID"
}

// ListUsersQuery lists all users
type ListUsersQuery struct {
	Limit  int
	Offset int
}

func (q ListUsersQuery) QueryName() string {
	return "ListUsers"
}

// SearchUsersQuery searches users by criteria
type SearchUsersQuery struct {
	Email string
	Name  string
}

func (q SearchUsersQuery) QueryName() string {
	return "SearchUsers"
}
