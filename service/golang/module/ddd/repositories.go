package ddd

import (
	"context"

	"github.com/google/uuid"
)

// OrderRepository defines the interface for order persistence
type OrderRepository interface {
	// Save persists an order
	Save(ctx context.Context, order *Order) error

	// FindByID retrieves an order by ID
	FindByID(ctx context.Context, id uuid.UUID) (*Order, error)

	// FindByCustomerID retrieves orders for a customer
	FindByCustomerID(ctx context.Context, customerID uuid.UUID) ([]*Order, error)

	// FindByStatus retrieves orders by status
	FindByStatus(ctx context.Context, status OrderStatus) ([]*Order, error)

	// Delete removes an order
	Delete(ctx context.Context, id uuid.UUID) error

	// NextID generates the next order ID
	NextID() uuid.UUID
}

// ProjectRepository defines the interface for project persistence
type ProjectRepository interface {
	Save(project *Project) error
	FindBySlug(slug string) (*Project, error)
}
