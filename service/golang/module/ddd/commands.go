package ddd

import (
	"context"

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
	orderRepo OrderRepository
}

// NewCreateOrderHandler creates a new create order handler
func NewCreateOrderHandler(orderRepo OrderRepository) *CreateOrderHandler {
	return &CreateOrderHandler{
		orderRepo: orderRepo,
	}
}

// Handle executes the create order command
func (h *CreateOrderHandler) Handle(ctx context.Context, cmd CreateOrderCommand) (uuid.UUID, error) {
	// Create new order aggregate
	order := NewOrder(cmd.CustomerID)

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

// CreateSubdomainCommand represents a command to create a subdomain
type CreateSubdomainCommand struct {
	ProjectSlug   string
	SubdomainName string
	Route         string
}

// CreateSubdomainHandler handles the create subdomain command
type CreateSubdomainHandler struct {
	routingService *RoutingService
	projectRepo    ProjectRepository
}

// NewCreateSubdomainHandler creates a new command handler
func NewCreateSubdomainHandler(
	routingService *RoutingService,
	projectRepo ProjectRepository,
) *CreateSubdomainHandler {
	return &CreateSubdomainHandler{
		routingService: routingService,
		projectRepo:    projectRepo,
	}
}

// Handle executes the create subdomain command
func (h *CreateSubdomainHandler) Handle(cmd CreateSubdomainCommand) error {
	project, err := h.routingService.GetProject(cmd.ProjectSlug)
	if err != nil {
		return err
	}

	if err := project.AddSubdomain(cmd.SubdomainName, cmd.Route); err != nil {
		return err
	}

	// Persist changes
	if err := h.projectRepo.Save(project); err != nil {
		return err
	}

	return nil
}
