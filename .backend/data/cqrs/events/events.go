package events

import "time"

// DomainEvent represents a domain event
type DomainEvent interface {
	EventType() string
	OccurredAt() time.Time
}

// BaseEvent provides common event fields
type BaseEvent struct {
	Timestamp time.Time `json:"timestamp"`
}

func (e BaseEvent) OccurredAt() time.Time {
	return e.Timestamp
}

// User Events

// UserCreatedEvent is published when a user is created
type UserCreatedEvent struct {
	BaseEvent
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	Name   string `json:"name"`
}

func (e UserCreatedEvent) EventType() string {
	return "UserCreated"
}

// UserUpdatedEvent is published when a user is updated
type UserUpdatedEvent struct {
	BaseEvent
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	Name   string `json:"name"`
}

func (e UserUpdatedEvent) EventType() string {
	return "UserUpdated"
}

// UserDeletedEvent is published when a user is deleted
type UserDeletedEvent struct {
	BaseEvent
	UserID string `json:"user_id"`
}

func (e UserDeletedEvent) EventType() string {
	return "UserDeleted"
}

// Order Events

// OrderCreatedEvent is published when an order is created
type OrderCreatedEvent struct {
	BaseEvent
	OrderID    string  `json:"order_id"`
	UserID     string  `json:"user_id"`
	TotalPrice float64 `json:"total_price"`
}

func (e OrderCreatedEvent) EventType() string {
	return "OrderCreated"
}

// OrderPaidEvent is published when an order is paid
type OrderPaidEvent struct {
	BaseEvent
	OrderID       string `json:"order_id"`
	PaymentMethod string `json:"payment_method"`
}

func (e OrderPaidEvent) EventType() string {
	return "OrderPaid"
}

// OrderShippedEvent is published when an order is shipped
type OrderShippedEvent struct {
	BaseEvent
	OrderID        string `json:"order_id"`
	TrackingNumber string `json:"tracking_number"`
}

func (e OrderShippedEvent) EventType() string {
	return "OrderShipped"
}

// OrderDeliveredEvent is published when an order is delivered
type OrderDeliveredEvent struct {
	BaseEvent
	OrderID     string    `json:"order_id"`
	DeliveredAt time.Time `json:"delivered_at"`
}

func (e OrderDeliveredEvent) EventType() string {
	return "OrderDelivered"
}

// OrderCancelledEvent is published when an order is cancelled
type OrderCancelledEvent struct {
	BaseEvent
	OrderID string `json:"order_id"`
	Reason  string `json:"reason"`
}

func (e OrderCancelledEvent) EventType() string {
	return "OrderCancelled"
}
