package valueobjects

import (
	"errors"
	"fmt"

	"github.com/shopspring/decimal"
)

// Currency represents a currency code (ISO 4217)
type Currency string

const (
	USD Currency = "USD"
	EUR Currency = "EUR"
	GBP Currency = "GBP"
	JPY Currency = "JPY"
	PLN Currency = "PLN"
)

// Money is a value object representing monetary value
type Money struct {
	amount   decimal.Decimal
	currency Currency
}

// NewMoney creates a new Money value object
func NewMoney(amount decimal.Decimal, currency Currency) (*Money, error) {
	if !isValidCurrency(currency) {
		return nil, fmt.Errorf("invalid currency: %s", currency)
	}

	return &Money{
		amount:   amount,
		currency: currency,
	}, nil
}

// Amount returns the monetary amount
func (m *Money) Amount() decimal.Decimal {
	return m.amount
}

// Currency returns the currency
func (m *Money) Currency() Currency {
	return m.currency
}

// Add adds two Money values (must be same currency)
func (m *Money) Add(other *Money) (*Money, error) {
	if m.currency != other.currency {
		return nil, errors.New("cannot add money with different currencies")
	}

	return &Money{
		amount:   m.amount.Add(other.amount),
		currency: m.currency,
	}, nil
}

// Subtract subtracts two Money values (must be same currency)
func (m *Money) Subtract(other *Money) (*Money, error) {
	if m.currency != other.currency {
		return nil, errors.New("cannot subtract money with different currencies")
	}

	return &Money{
		amount:   m.amount.Sub(other.amount),
		currency: m.currency,
	}, nil
}

// Multiply multiplies money by a factor
func (m *Money) Multiply(factor decimal.Decimal) *Money {
	return &Money{
		amount:   m.amount.Mul(factor),
		currency: m.currency,
	}
}

// IsZero checks if amount is zero
func (m *Money) IsZero() bool {
	return m.amount.IsZero()
}

// IsPositive checks if amount is positive
func (m *Money) IsPositive() bool {
	return m.amount.GreaterThan(decimal.Zero)
}

// IsNegative checks if amount is negative
func (m *Money) IsNegative() bool {
	return m.amount.LessThan(decimal.Zero)
}

// Equals checks if two Money values are equal
func (m *Money) Equals(other *Money) bool {
	return m.currency == other.currency && m.amount.Equal(other.amount)
}

// String returns string representation
func (m *Money) String() string {
	return fmt.Sprintf("%s %s", m.amount.StringFixed(2), m.currency)
}

func isValidCurrency(currency Currency) bool {
	validCurrencies := []Currency{USD, EUR, GBP, JPY, PLN}
	for _, c := range validCurrencies {
		if c == currency {
			return true
		}
	}
	return false
}

// Email is a value object representing an email address
type Email struct {
	address string
}

// NewEmail creates a new Email value object
func NewEmail(address string) (*Email, error) {
	// Simplified validation - use proper regex in production
	if len(address) < 3 || !contains(address, "@") {
		return nil, errors.New("invalid email address")
	}

	return &Email{address: address}, nil
}

// Address returns the email address
func (e *Email) Address() string {
	return e.address
}

// Equals checks if two Email values are equal
func (e *Email) Equals(other *Email) bool {
	return e.address == other.address
}

// String returns string representation
func (e *Email) String() string {
	return e.address
}

func contains(s, substr string) bool {
	for i := 0; i <= len(s)-len(substr); i++ {
		if s[i:i+len(substr)] == substr {
			return true
		}
	}
	return false
}

// Address is a value object representing a physical address
type Address struct {
	street     string
	city       string
	state      string
	postalCode string
	country    string
}

// NewAddress creates a new Address value object
func NewAddress(street, city, state, postalCode, country string) (*Address, error) {
	if street == "" || city == "" || country == "" {
		return nil, errors.New("street, city, and country are required")
	}

	return &Address{
		street:     street,
		city:       city,
		state:      state,
		postalCode: postalCode,
		country:    country,
	}, nil
}

// Street returns the street
func (a *Address) Street() string {
	return a.street
}

// City returns the city
func (a *Address) City() string {
	return a.city
}

// State returns the state
func (a *Address) State() string {
	return a.state
}

// PostalCode returns the postal code
func (a *Address) PostalCode() string {
	return a.postalCode
}

// Country returns the country
func (a *Address) Country() string {
	return a.country
}

// Equals checks if two Address values are equal
func (a *Address) Equals(other *Address) bool {
	return a.street == other.street &&
		a.city == other.city &&
		a.state == other.state &&
		a.postalCode == other.postalCode &&
		a.country == other.country
}

// String returns string representation
func (a *Address) String() string {
	return fmt.Sprintf("%s, %s, %s %s, %s", a.street, a.city, a.state, a.postalCode, a.country)
}
