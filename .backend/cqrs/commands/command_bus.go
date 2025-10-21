package commands

import (
	"context"
	"fmt"
	"sync"
)

// Command represents a command in the system
type Command interface {
	CommandName() string
}

// CommandHandler handles a specific command type
type CommandHandler interface {
	Handle(ctx context.Context, cmd Command) error
}

// CommandBus routes commands to their handlers
type CommandBus struct {
	handlers map[string]CommandHandler
	mu       sync.RWMutex
}

// NewCommandBus creates a new command bus
func NewCommandBus() *CommandBus {
	return &CommandBus{
		handlers: make(map[string]CommandHandler),
	}
}

// Register registers a handler for a command type
func (cb *CommandBus) Register(commandName string, handler CommandHandler) {
	cb.mu.Lock()
	defer cb.mu.Unlock()
	cb.handlers[commandName] = handler
}

// Execute executes a command
func (cb *CommandBus) Execute(ctx context.Context, cmd Command) error {
	cb.mu.RLock()
	handler, exists := cb.handlers[cmd.CommandName()]
	cb.mu.RUnlock()

	if !exists {
		return fmt.Errorf("no handler registered for command: %s", cmd.CommandName())
	}

	return handler.Handle(ctx, cmd)
}

// Example Commands

// CreateUserCommand creates a new user
type CreateUserCommand struct {
	UserID string
	Email  string
	Name   string
}

func (c CreateUserCommand) CommandName() string {
	return "CreateUser"
}

// UpdateUserCommand updates user details
type UpdateUserCommand struct {
	UserID string
	Email  string
	Name   string
}

func (c UpdateUserCommand) CommandName() string {
	return "UpdateUser"
}

// DeleteUserCommand deletes a user
type DeleteUserCommand struct {
	UserID string
}

func (c DeleteUserCommand) CommandName() string {
	return "DeleteUser"
}
