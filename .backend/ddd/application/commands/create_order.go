package commands

import (
	"context"
	"ddd/domain/entities"
	"ddd/domain/repositories"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// CreateOrderCommand represents a command to create an order
type CreateOrderCommand struct {
	CustomerID uuid.UUID
	Items      []OrderItemDTO
}

// OrderItemDTO represents an order item data transfer object
type OrderItemDTO struct {
	ProductID   uuid.UUID
	ProductName string
	Quantity    int
	UnitPrice   decimal.Decimal
}

// CreateOrderHandler handles the create order command
type CreateOrderHandler struct {
	orderRepo repositories.OrderRepository
}

// NewCreateOrderHandler creates a new create order handler
func NewCreateOrderHandler(orderRepo repositories.OrderRepository) *CreateOrderHandler {
	return &CreateOrderHandler{
		orderRepo: orderRepo,
	}
}

// Handle executes the create order command
func (h *CreateOrderHandler) Handle(ctx context.Context, cmd CreateOrderCommand) (uuid.UUID, error) {
	// Create new order aggregate
	order := entities.NewOrder(cmd.CustomerID)

	// Add items to order
	for _, item := range cmd.Items {
		err := order.AddItem(item.ProductID, item.ProductName, item.Quantity, item.UnitPrice)
		if err != nil {
			return uuid.Nil, err
		}
	}

	// Submit order
	if err := order.Submit(); err != nil {
		return uuid.Nil, err
	}

	// Persist order
	if err := h.orderRepo.Save(ctx, order); err != nil {
		return uuid.Nil, err
	}

	return order.ID(), nil
}
