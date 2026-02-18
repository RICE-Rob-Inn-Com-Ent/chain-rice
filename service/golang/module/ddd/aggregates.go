package ddd

import (
	"errors"
	"time"

	"github.com/google/uuid"
	"github.com/shopspring/decimal"
)

// ============================================================================
// Order Aggregate
// ============================================================================

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

// ============================================================================
// Project Aggregate
// ============================================================================

// ProjectStatus represents project lifecycle
type ProjectStatus string

const (
	ProjectStatusActive   ProjectStatus = "ACTIVE"
	ProjectStatusInactive ProjectStatus = "INACTIVE"
	ProjectStatusArchived ProjectStatus = "ARCHIVED"
)

// Project is an aggregate root representing a project (code_rice, ceramix, meowtopia)
type Project struct {
	id         uuid.UUID
	name       string
	slug       string
	status     ProjectStatus
	subdomains []Subdomain
	createdAt  time.Time
	updatedAt  time.Time
}

// NewProject creates a new project
func NewProject(name, slug string) (*Project, error) {
	if name == "" {
		return nil, errors.New("project name cannot be empty")
	}
	if slug == "" {
		return nil, errors.New("project slug cannot be empty")
	}

	return &Project{
		id:         uuid.New(),
		name:       name,
		slug:       slug,
		status:     ProjectStatusActive,
		subdomains: make([]Subdomain, 0),
		createdAt:  time.Now(),
		updatedAt:  time.Now(),
	}, nil
}

// ID returns project identifier
func (p *Project) ID() uuid.UUID {
	return p.id
}

// Name returns project name
func (p *Project) Name() string {
	return p.name
}

// Slug returns project slug
func (p *Project) Slug() string {
	return p.slug
}

// Status returns project status
func (p *Project) Status() ProjectStatus {
	return p.status
}

// Subdomains returns project subdomains (defensive copy)
func (p *Project) Subdomains() []Subdomain {
	subdomains := make([]Subdomain, len(p.subdomains))
	copy(subdomains, p.subdomains)
	return subdomains
}

// AddSubdomain adds a subdomain to the project
func (p *Project) AddSubdomain(name, route string) error {
	if p.status != ProjectStatusActive {
		return errors.New("cannot add subdomain to inactive project")
	}

	if name == "" {
		return errors.New("subdomain name cannot be empty")
	}

	// Check if subdomain already exists
	for _, sub := range p.subdomains {
		if sub.Name() == name {
			return errors.New("subdomain already exists")
		}
	}

	subdomain, err := NewSubdomain(name, route)
	if err != nil {
		return err
	}

	p.subdomains = append(p.subdomains, *subdomain)
	p.updatedAt = time.Now()

	return nil
}

// RemoveSubdomain removes a subdomain from the project
func (p *Project) RemoveSubdomain(name string) error {
	if p.status != ProjectStatusActive {
		return errors.New("cannot remove subdomain from inactive project")
	}

	for i, sub := range p.subdomains {
		if sub.Name() == name {
			p.subdomains = append(p.subdomains[:i], p.subdomains[i+1:]...)
			p.updatedAt = time.Now()
			return nil
		}
	}

	return errors.New("subdomain not found")
}

// Activate activates the project
func (p *Project) Activate() {
	p.status = ProjectStatusActive
	p.updatedAt = time.Now()
}

// Deactivate deactivates the project
func (p *Project) Deactivate() {
	p.status = ProjectStatusInactive
	p.updatedAt = time.Now()
}

// Archive archives the project
func (p *Project) Archive() {
	p.status = ProjectStatusArchived
	p.updatedAt = time.Now()
}

// ============================================================================
// Subdomain Value Object
// ============================================================================

// SubdomainType represents the type of subdomain
type SubdomainType string

const (
	SubdomainTypeAdmin SubdomainType = "admin"
	SubdomainTypeMain  SubdomainType = "main"
	SubdomainTypeAuth  SubdomainType = "auth"
)

// Subdomain is a value object representing a subdomain routing configuration
type Subdomain struct {
	id            uuid.UUID
	name          string
	subdomainType SubdomainType
	route         string
	targetURL     string
	createdAt     time.Time
	updatedAt     time.Time
}

// NewSubdomain creates a new subdomain
func NewSubdomain(name, route string) (*Subdomain, error) {
	if name == "" {
		return nil, errors.New("subdomain name cannot be empty")
	}
	if route == "" {
		return nil, errors.New("route cannot be empty")
	}

	// Determine subdomain type from name
	var subdomainType SubdomainType
	switch name {
	case "admin":
		subdomainType = SubdomainTypeAdmin
	case "main":
		subdomainType = SubdomainTypeMain
	case "auth":
		subdomainType = SubdomainTypeAuth
	default:
		return nil, errors.New("invalid subdomain type")
	}

	return &Subdomain{
		id:            uuid.New(),
		name:          name,
		subdomainType: subdomainType,
		route:         route,
		targetURL:     "", // Will be set by routing service
		createdAt:     time.Now(),
		updatedAt:     time.Now(),
	}, nil
}

// ID returns subdomain identifier
func (s *Subdomain) ID() uuid.UUID {
	return s.id
}

// Name returns subdomain name
func (s *Subdomain) Name() string {
	return s.name
}

// Type returns subdomain type
func (s *Subdomain) Type() SubdomainType {
	return s.subdomainType
}

// Route returns the route path
func (s *Subdomain) Route() string {
	return s.route
}

// TargetURL returns the target URL
func (s *Subdomain) TargetURL() string {
	return s.targetURL
}

// SetTargetURL sets the target URL
func (s *Subdomain) SetTargetURL(url string) error {
	if url == "" {
		return errors.New("target URL cannot be empty")
	}
	s.targetURL = url
	s.updatedAt = time.Now()
	return nil
}

// UpdateRoute updates the route
func (s *Subdomain) UpdateRoute(route string) error {
	if route == "" {
		return errors.New("route cannot be empty")
	}
	s.route = route
	s.updatedAt = time.Now()
	return nil
}
