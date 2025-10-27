package entities

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// OrderStatus represents the order lifecycle
type OrderStatus string

const (
	OrderStatusDraft     OrderStatus = "DRAFT"
	OrderStatusPending   OrderStatus = "PENDING"
	OrderStatusPaid      OrderStatus = "PAID"
	OrderStatusShipped   OrderStatus = "SHIPPED"
	OrderStatusDelivered OrderStatus = "DELIVERED"
	OrderStatusCancelled OrderStatus = "CANCELLED"
)

// Order is an aggregate root
type Order struct {
	id         uuid.UUID
	customerID uuid.UUID
	items      []OrderItem
	status     OrderStatus
	totalPrice decimal.Decimal
	createdAt  time.Time
	updatedAt  time.Time
}

// NewOrder creates a new order (factory method)
func NewOrder(customerID uuid.UUID) *Order {
	return &Order{
		id:         uuid.New(),
		customerID: customerID,
		items:      make([]OrderItem, 0),
		status:     OrderStatusDraft,
		totalPrice: decimal.Zero,
		createdAt:  time.Now(),
		updatedAt:  time.Now(),
	}
}

// ID returns order identifier
func (o *Order) ID() uuid.UUID {
	return o.id
}

// CustomerID returns customer identifier
func (o *Order) CustomerID() uuid.UUID {
	return o.customerID
}

// Status returns order status
func (o *Order) Status() OrderStatus {
	return o.status
}

// TotalPrice returns total order price
func (o *Order) TotalPrice() decimal.Decimal {
	return o.totalPrice
}

// Items returns order items (defensive copy)
func (o *Order) Items() []OrderItem {
	items := make([]OrderItem, len(o.items))
	copy(items, o.items)
	return items
}

// AddItem adds an item to the order
func (o *Order) AddItem(productID uuid.UUID, productName string, quantity int, unitPrice decimal.Decimal) error {
	// Business rule: can only add items to draft orders
	if o.status != OrderStatusDraft {
		return errors.New("cannot add items to non-draft order")
	}

	// Business rule: quantity must be positive
	if quantity <= 0 {
		return errors.New("quantity must be positive")
	}

	// Business rule: unit price must be positive
	if unitPrice.LessThanOrEqual(decimal.Zero) {
		return errors.New("unit price must be positive")
	}

	item := OrderItem{
		id:          uuid.New(),
		productID:   productID,
		productName: productName,
		quantity:    quantity,
		unitPrice:   unitPrice,
		totalPrice:  unitPrice.Mul(decimal.NewFromInt(int64(quantity))),
	}

	o.items = append(o.items, item)
	o.recalculateTotal()
	o.updatedAt = time.Now()

	return nil
}

// RemoveItem removes an item from the order
func (o *Order) RemoveItem(itemID uuid.UUID) error {
	if o.status != OrderStatusDraft {
		return errors.New("cannot remove items from non-draft order")
	}

	for i, item := range o.items {
		if item.id == itemID {
			o.items = append(o.items[:i], o.items[i+1:]...)
			o.recalculateTotal()
			o.updatedAt = time.Now()
			return nil
		}
	}

	return errors.New("item not found")
}

// Submit submits the order for processing
func (o *Order) Submit() error {
	// Business rule: order must have items
	if len(o.items) == 0 {
		return errors.New("cannot submit empty order")
	}

	// Business rule: order must be in draft status
	if o.status != OrderStatusDraft {
		return errors.New("order already submitted")
	}

	o.status = OrderStatusPending
	o.updatedAt = time.Now()

	return nil
}

// MarkAsPaid marks the order as paid
func (o *Order) MarkAsPaid() error {
	if o.status != OrderStatusPending {
		return errors.New("can only pay pending orders")
	}

	o.status = OrderStatusPaid
	o.updatedAt = time.Now()

	return nil
}

// Ship ships the order
func (o *Order) Ship() error {
	if o.status != OrderStatusPaid {
		return errors.New("can only ship paid orders")
	}

	o.status = OrderStatusShipped
	o.updatedAt = time.Now()

	return nil
}

// MarkAsDelivered marks the order as delivered
func (o *Order) MarkAsDelivered() error {
	if o.status != OrderStatusShipped {
		return errors.New("can only deliver shipped orders")
	}

	o.status = OrderStatusDelivered
	o.updatedAt = time.Now()

	return nil
}

// Cancel cancels the order
func (o *Order) Cancel() error {
	// Business rule: cannot cancel delivered orders
	if o.status == OrderStatusDelivered {
		return errors.New("cannot cancel delivered order")
	}

	// Business rule: cannot cancel already cancelled orders
	if o.status == OrderStatusCancelled {
		return errors.New("order already cancelled")
	}

	o.status = OrderStatusCancelled
	o.updatedAt = time.Now()

	return nil
}

// recalculateTotal recalculates the order total
func (o *Order) recalculateTotal() {
	total := decimal.Zero
	for _, item := range o.items {
		total = total.Add(item.totalPrice)
	}
	o.totalPrice = total
}

// OrderItem represents a single item in an order (entity within aggregate)
type OrderItem struct {
	id          uuid.UUID
	productID   uuid.UUID
	productName string
	quantity    int
	unitPrice   decimal.Decimal
	totalPrice  decimal.Decimal
}

// ID returns item identifier
func (oi *OrderItem) ID() uuid.UUID {
	return oi.id
}

// ProductID returns product identifier
func (oi *OrderItem) ProductID() uuid.UUID {
	return oi.productID
}

// ProductName returns product name
func (oi *OrderItem) ProductName() string {
	return oi.productName
}

// Quantity returns item quantity
func (oi *OrderItem) Quantity() int {
	return oi.quantity
}

// UnitPrice returns unit price
func (oi *OrderItem) UnitPrice() decimal.Decimal {
	return oi.unitPrice
}

// TotalPrice returns total price for this item
func (oi *OrderItem) TotalPrice() decimal.Decimal {
	return oi.totalPrice
}
