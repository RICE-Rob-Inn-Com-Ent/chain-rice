package repositories

import (
	"context"
	"ddd/domain/entities"

	"github.com/google/uuid"
)

// OrderRepository defines the interface for order persistence
// This is part of the domain layer but implemented in infrastructure layer
type OrderRepository interface {
	// Save persists an order
	Save(ctx context.Context, order *entities.Order) error

	// FindByID retrieves an order by ID
	FindByID(ctx context.Context, id uuid.UUID) (*entities.Order, error)

	// FindByCustomerID retrieves orders for a customer
	FindByCustomerID(ctx context.Context, customerID uuid.UUID) ([]*entities.Order, error)

	// FindByStatus retrieves orders by status
	FindByStatus(ctx context.Context, status entities.OrderStatus) ([]*entities.Order, error)

	// Delete removes an order
	Delete(ctx context.Context, id uuid.UUID) error

	// NextID generates the next order ID
	NextID() uuid.UUID
}
