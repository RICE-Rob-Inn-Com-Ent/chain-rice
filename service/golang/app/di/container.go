package di

import (
	"context"
	"fmt"
	"sync"
)

// Container provides dependency injection functionality
type Container struct {
	mu          sync.RWMutex
	services    map[string]interface{}
	factories   map[string]func(*Container) (interface{}, error)
	singletons  map[string]bool
	initialized map[string]bool
}

// NewContainer creates a new dependency injection container
func NewContainer() *Container {
	return &Container{
		services:    make(map[string]interface{}),
		factories:   make(map[string]func(*Container) (interface{}, error)),
		singletons:  make(map[string]bool),
		initialized: make(map[string]bool),
	}
}

// Register registers a service instance
func (c *Container) Register(name string, service interface{}) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.services[name] = service
	c.initialized[name] = true
}

// RegisterFactory registers a factory function for lazy initialization
func (c *Container) RegisterFactory(name string, factory func(*Container) (interface{}, error), singleton bool) {
	c.mu.Lock()
	defer c.mu.Unlock()
	c.factories[name] = factory
	c.singletons[name] = singleton
}

// Get retrieves a service by name
func (c *Container) Get(name string) (interface{}, error) {
	c.mu.RLock()

	// Check if already initialized
	if service, ok := c.services[name]; ok {
		c.mu.RUnlock()
		return service, nil
	}

	// Check if factory exists
	factory, hasFactory := c.factories[name]
	singleton := c.singletons[name]
	c.mu.RUnlock()

	if !hasFactory {
		return nil, fmt.Errorf("service %s not found", name)
	}

	// Initialize from factory
	c.mu.Lock()
	defer c.mu.Unlock()

	// Double-check after acquiring write lock
	if service, ok := c.services[name]; ok {
		return service, nil
	}

	service, err := factory(c)
	if err != nil {
		return nil, fmt.Errorf("failed to create service %s: %w", name, err)
	}

	if singleton {
		c.services[name] = service
		c.initialized[name] = true
	}

	return service, nil
}

// MustGet retrieves a service and panics if not found
func (c *Container) GetTyped(name string, target interface{}) error {
	service, err := c.Get(name)
	if err != nil {
		return err
	}

	// Type assertion helper - caller should use type assertion
	// This is a simplified version; for full type safety, use generics (Go 1.18+)
	if targetPtr, ok := target.(*interface{}); ok {
		*targetPtr = service
		return nil
	}

	return fmt.Errorf("cannot assign service %s to target", name)
}

// MustGet retrieves a service and panics if not found
func (c *Container) MustGet(name string) interface{} {
	service, err := c.Get(name)
	if err != nil {
		panic(fmt.Sprintf("service %s not found: %v", name, err))
	}
	return service
}

// Has checks if a service is registered
func (c *Container) Has(name string) bool {
	c.mu.RLock()
	defer c.mu.RUnlock()
	_, hasService := c.services[name]
	_, hasFactory := c.factories[name]
	return hasService || hasFactory
}

// Shutdown gracefully shuts down all services that implement Shutdowner interface
func (c *Container) Shutdown(ctx context.Context) error {
	c.mu.RLock()
	defer c.mu.RUnlock()

	var errs []error
	for name, service := range c.services {
		if shutdowner, ok := service.(Shutdowner); ok {
			if err := shutdowner.Shutdown(ctx); err != nil {
				errs = append(errs, fmt.Errorf("error shutting down %s: %w", name, err))
			}
		}
	}

	if len(errs) > 0 {
		return fmt.Errorf("shutdown errors: %v", errs)
	}

	return nil
}

// Shutdowner interface for services that need cleanup
type Shutdowner interface {
	Shutdown(ctx context.Context) error
}
