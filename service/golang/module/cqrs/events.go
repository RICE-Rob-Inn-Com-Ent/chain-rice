package cqrs

import (
	"time"
)

// CQRSDomainEvent represents a domain event
type CQRSDomainEvent interface {
	EventType() string
	OccurredAt() time.Time
}

// CQRSBaseEvent provides common event fields
type CQRSBaseEvent struct {
	Timestamp time.Time `json:"timestamp"`
}

func (e CQRSBaseEvent) OccurredAt() time.Time {
	return e.Timestamp
}

// User Events

// CQRSUserCreatedEvent is published when a user is created
type CQRSUserCreatedEvent struct {
	CQRSBaseEvent
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	Name   string `json:"name"`
}

func (e CQRSUserCreatedEvent) EventType() string {
	return "UserCreated"
}

// CQRSUserUpdatedEvent is published when a user is updated
type CQRSUserUpdatedEvent struct {
	CQRSBaseEvent
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	Name   string `json:"name"`
}

func (e CQRSUserUpdatedEvent) EventType() string {
	return "UserUpdated"
}

// CQRSUserDeletedEvent is published when a user is deleted
type CQRSUserDeletedEvent struct {
	CQRSBaseEvent
	UserID string `json:"user_id"`
}

func (e CQRSUserDeletedEvent) EventType() string {
	return "UserDeleted"
}

// Order Events

// CQRSOrderCreatedEvent is published when an order is created
type CQRSOrderCreatedEvent struct {
	CQRSBaseEvent
	OrderID    string  `json:"order_id"`
	UserID     string  `json:"user_id"`
	TotalPrice float64 `json:"total_price"`
}

func (e CQRSOrderCreatedEvent) EventType() string {
	return "OrderCreated"
}

// CQRSOrderPaidEvent is published when an order is paid
type CQRSOrderPaidEvent struct {
	CQRSBaseEvent
	OrderID       string `json:"order_id"`
	PaymentMethod string `json:"payment_method"`
}

func (e CQRSOrderPaidEvent) EventType() string {
	return "OrderPaid"
}

// CQRSOrderShippedEvent is published when an order is shipped
type CQRSOrderShippedEvent struct {
	CQRSBaseEvent
	OrderID        string `json:"order_id"`
	TrackingNumber string `json:"tracking_number"`
}

func (e CQRSOrderShippedEvent) EventType() string {
	return "OrderShipped"
}

// CQRSOrderDeliveredEvent is published when an order is delivered
type CQRSOrderDeliveredEvent struct {
	CQRSBaseEvent
	OrderID     string    `json:"order_id"`
	DeliveredAt time.Time `json:"delivered_at"`
}

func (e CQRSOrderDeliveredEvent) EventType() string {
	return "OrderDelivered"
}

// CQRSOrderCancelledEvent is published when an order is cancelled
type CQRSOrderCancelledEvent struct {
	CQRSBaseEvent
	OrderID string `json:"order_id"`
	Reason  string `json:"reason"`
}

func (e CQRSOrderCancelledEvent) EventType() string {
	return "OrderCancelled"
}
