package cqrs

import (
	"context"
	"fmt"
	"sync"
)

// CQRSCommand represents a command in the system
type CQRSCommand interface {
	CommandName() string
}

// CQRSCommandHandler handles a specific command type
type CQRSCommandHandler interface {
	Handle(ctx context.Context, cmd CQRSCommand) error
}

// CQRSCommandBus routes commands to their handlers
type CQRSCommandBus struct {
	handlers map[string]CQRSCommandHandler
	mu       sync.RWMutex
}

// NewCommandBus creates a new command bus
func NewCommandBus() *CQRSCommandBus {
	return &CQRSCommandBus{
		handlers: make(map[string]CQRSCommandHandler),
	}
}

// CQRSNewCommandBus is deprecated, use NewCommandBus instead
// Deprecated: Use NewCommandBus for consistency
func CQRSNewCommandBus() *CQRSCommandBus {
	return NewCommandBus()
}

// Register registers a handler for a command type
func (cb *CQRSCommandBus) Register(commandName string, handler CQRSCommandHandler) {
	cb.mu.Lock()
	defer cb.mu.Unlock()
	cb.handlers[commandName] = handler
}

// Execute executes a command
func (cb *CQRSCommandBus) Execute(ctx context.Context, cmd CQRSCommand) error {
	if cmd == nil {
		return fmt.Errorf("command cannot be nil")
	}

	if ctx == nil {
		return fmt.Errorf("context cannot be nil")
	}

	// Check context cancellation
	if err := ctx.Err(); err != nil {
		return fmt.Errorf("context cancelled: %w", err)
	}

	commandName := cmd.CommandName()
	if commandName == "" {
		return fmt.Errorf("command name cannot be empty")
	}

	cb.mu.RLock()
	handler, exists := cb.handlers[commandName]
	cb.mu.RUnlock()

	if !exists {
		return fmt.Errorf("no handler registered for command: %s", commandName)
	}

	if handler == nil {
		return fmt.Errorf("handler for command %s is nil", commandName)
	}

	return handler.Handle(ctx, cmd)
}

// Example Commands

// CQRSCreateUserCommand creates a new user
type CQRSCreateUserCommand struct {
	UserID string
	Email  string
	Name   string
}

func (c CQRSCreateUserCommand) CommandName() string {
	return "CreateUser"
}

// CQRSUpdateUserCommand updates user details
type CQRSUpdateUserCommand struct {
	UserID string
	Email  string
	Name   string
}

func (c CQRSUpdateUserCommand) CommandName() string {
	return "UpdateUser"
}

// CQRSDeleteUserCommand deletes a user
type CQRSDeleteUserCommand struct {
	UserID string
}

func (c CQRSDeleteUserCommand) CommandName() string {
	return "DeleteUser"
}
