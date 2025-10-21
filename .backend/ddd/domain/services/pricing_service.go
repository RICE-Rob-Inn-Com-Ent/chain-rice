package services

import (
	"ddd/domain/entities"
	"ddd/domain/valueobjects"

	"github.com/shopspring/decimal"
)

// PricingService is a domain service for pricing calculations
type PricingService struct {
	taxRate      decimal.Decimal
	discountRate decimal.Decimal
}

// NewPricingService creates a new pricing service
func NewPricingService(taxRate, discountRate decimal.Decimal) *PricingService {
	return &PricingService{
		taxRate:      taxRate,
		discountRate: discountRate,
	}
}

// CalculateOrderTotal calculates the total for an order including tax and discounts
func (ps *PricingService) CalculateOrderTotal(order *entities.Order) (*valueobjects.Money, error) {
	subtotal := order.TotalPrice()

	// Apply discount
	discount := subtotal.Mul(ps.discountRate)
	afterDiscount := subtotal.Sub(discount)

	// Apply tax
	tax := afterDiscount.Mul(ps.taxRate)
	total := afterDiscount.Add(tax)

	return valueobjects.NewMoney(total, valueobjects.USD)
}

// ApplyBulkDiscount applies a bulk discount if order meets criteria
func (ps *PricingService) ApplyBulkDiscount(order *entities.Order, threshold int) decimal.Decimal {
	itemCount := 0
	for _, item := range order.Items() {
		itemCount += item.Quantity()
	}

	if itemCount >= threshold {
		return decimal.NewFromFloat(0.1) // 10% discount
	}

	return decimal.Zero
}

// CalculateShippingCost calculates shipping cost based on order weight and destination
func (ps *PricingService) CalculateShippingCost(totalWeight decimal.Decimal, destination string) (*valueobjects.Money, error) {
	baseRate := decimal.NewFromFloat(10.0)
	perKgRate := decimal.NewFromFloat(2.5)

	shippingCost := baseRate.Add(totalWeight.Mul(perKgRate))

	// International shipping surcharge
	if destination != "US" {
		shippingCost = shippingCost.Mul(decimal.NewFromFloat(1.5))
	}

	return valueobjects.NewMoney(shippingCost, valueobjects.USD)
}
