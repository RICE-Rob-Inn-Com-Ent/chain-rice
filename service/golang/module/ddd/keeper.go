package ddd

import (
	"context"
	"fmt"

	"github.com/google/uuid"
)

// DDDKeeper manages DDD domain operations
type DDDKeeper struct {
	orderRepo      OrderRepository
	pricingService *PricingService
	routingService *RoutingService
}

// NewDDDKeeper creates a new DDD keeper
func NewDDDKeeper(
	orderRepo OrderRepository,
	pricingService *PricingService,
	routingService *RoutingService,
) *DDDKeeper {
	return &DDDKeeper{
		orderRepo:      orderRepo,
		pricingService: pricingService,
		routingService: routingService,
	}
}

// GetOrderRepository returns the order repository
func (k *DDDKeeper) GetOrderRepository() OrderRepository {
	return k.orderRepo
}

// GetPricingService returns the pricing service
func (k *DDDKeeper) GetPricingService() *PricingService {
	return k.pricingService
}

// GetRoutingService returns the routing service
func (k *DDDKeeper) GetRoutingService() *RoutingService {
	return k.routingService
}

// CreateOrder creates a new order
func (k *DDDKeeper) CreateOrder(ctx context.Context, customerID uuid.UUID) (*Order, error) {
	if ctx == nil {
		return nil, fmt.Errorf("context cannot be nil")
	}

	if customerID == (uuid.UUID{}) {
		return nil, fmt.Errorf("customer ID cannot be zero")
	}

	if k.orderRepo == nil {
		return nil, fmt.Errorf("order repository is nil")
	}

	if err := ctx.Err(); err != nil {
		return nil, fmt.Errorf("context cancelled: %w", err)
	}

	order := NewOrder(customerID)
	if err := k.orderRepo.Save(ctx, order); err != nil {
		return nil, fmt.Errorf("failed to save order: %w", err)
	}
	return order, nil
}

// GetOrder retrieves an order by ID
func (k *DDDKeeper) GetOrder(ctx context.Context, id uuid.UUID) (*Order, error) {
	if ctx == nil {
		return nil, fmt.Errorf("context cannot be nil")
	}

	if id == (uuid.UUID{}) {
		return nil, fmt.Errorf("order ID cannot be zero")
	}

	if k.orderRepo == nil {
		return nil, fmt.Errorf("order repository is nil")
	}

	if err := ctx.Err(); err != nil {
		return nil, fmt.Errorf("context cancelled: %w", err)
	}

	order, err := k.orderRepo.FindByID(ctx, id)
	if err != nil {
		return nil, fmt.Errorf("failed to find order: %w", err)
	}

	return order, nil
}
