package ddd

import (
	"errors"
	"fmt"

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
func (ps *PricingService) CalculateOrderTotal(order *Order) (*Money, error) {
	subtotal := order.TotalPrice()

	// Apply discount
	discount := subtotal.Mul(ps.discountRate)
	afterDiscount := subtotal.Sub(discount)

	// Apply tax
	tax := afterDiscount.Mul(ps.taxRate)
	total := afterDiscount.Add(tax)

	return NewMoney(total, USD)
}

// ApplyBulkDiscount applies a bulk discount if order meets criteria
func (ps *PricingService) ApplyBulkDiscount(order *Order, threshold int) decimal.Decimal {
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
func (ps *PricingService) CalculateShippingCost(totalWeight decimal.Decimal, destination string) (*Money, error) {
	baseRate := decimal.NewFromFloat(10.0)
	perKgRate := decimal.NewFromFloat(2.5)

	shippingCost := baseRate.Add(totalWeight.Mul(perKgRate))

	// International shipping surcharge
	if destination != "US" {
		shippingCost = shippingCost.Mul(decimal.NewFromFloat(1.5))
	}

	return NewMoney(shippingCost, USD)
}

// RoutingService is a domain service for managing subdomain routing
type RoutingService struct {
	projects map[string]*Project
}

// NewRoutingService creates a new routing service
func NewRoutingService() *RoutingService {
	return &RoutingService{
		projects: make(map[string]*Project),
	}
}

// RegisterProject registers a project with its default subdomains
func (rs *RoutingService) RegisterProject(name, slug string) (*Project, error) {
	if _, exists := rs.projects[slug]; exists {
		return nil, errors.New("project already registered")
	}

	project, err := NewProject(name, slug)
	if err != nil {
		return nil, err
	}

	// Add default subdomains: admin, main, auth
	defaultSubdomains := []struct {
		name  string
		route string
	}{
		{"admin", "/admin"},
		{"main", "/"},
		{"auth", "/auth"},
	}

	for _, sub := range defaultSubdomains {
		if err := project.AddSubdomain(sub.name, sub.route); err != nil {
			return nil, fmt.Errorf("failed to add subdomain %s: %w", sub.name, err)
		}
	}

	rs.projects[slug] = project
	return project, nil
}

// GetProject retrieves a project by slug
func (rs *RoutingService) GetProject(slug string) (*Project, error) {
	project, exists := rs.projects[slug]
	if !exists {
		return nil, errors.New("project not found")
	}
	return project, nil
}

// ResolveSubdomain resolves a subdomain to its target route
func (rs *RoutingService) ResolveSubdomain(projectSlug, subdomainName string) (string, error) {
	project, err := rs.GetProject(projectSlug)
	if err != nil {
		return "", err
	}

	if project.Status() != ProjectStatusActive {
		return "", errors.New("project is not active")
	}

	for _, subdomain := range project.Subdomains() {
		if subdomain.Name() == subdomainName {
			return subdomain.Route(), nil
		}
	}

	return "", errors.New("subdomain not found")
}

// BuildSubdomainURL builds the full subdomain URL
func (rs *RoutingService) BuildSubdomainURL(projectSlug, subdomainName string) (string, error) {
	project, err := rs.GetProject(projectSlug)
	if err != nil {
		return "", err
	}

	for _, subdomain := range project.Subdomains() {
		if subdomain.Name() == subdomainName {
			// Format: subdomain.project-slug.localhost
			return fmt.Sprintf("%s.%s.localhost", subdomainName, projectSlug), nil
		}
	}

	return "", errors.New("subdomain not found")
}

// GetAllProjects returns all registered projects
func (rs *RoutingService) GetAllProjects() []*Project {
	projects := make([]*Project, 0, len(rs.projects))
	for _, project := range rs.projects {
		projects = append(projects, project)
	}
	return projects
}
