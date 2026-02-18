package cqrs

import (
	"context"
	"fmt"
)

// CQRSKeeper manages CQRS operations
type CQRSKeeper struct {
	commandBus *CQRSCommandBus
	queryBus   *CQRSQueryBus
	eventStore CQRSEventStore
}

// NewKeeper creates a new CQRS keeper
func NewKeeper(
	commandBus *CQRSCommandBus,
	queryBus *CQRSQueryBus,
	eventStore CQRSEventStore,
) *CQRSKeeper {
	return &CQRSKeeper{
		commandBus: commandBus,
		queryBus:   queryBus,
		eventStore: eventStore,
	}
}

// CQRSNewKeeper is deprecated, use NewKeeper instead
// Deprecated: Use NewKeeper for consistency
func CQRSNewKeeper(
	commandBus *CQRSCommandBus,
	queryBus *CQRSQueryBus,
	eventStore CQRSEventStore,
) *CQRSKeeper {
	return NewKeeper(commandBus, queryBus, eventStore)
}

// GetCommandBus returns the command bus
func (k *CQRSKeeper) GetCommandBus() *CQRSCommandBus {
	return k.commandBus
}

// GetQueryBus returns the query bus
func (k *CQRSKeeper) GetQueryBus() *CQRSQueryBus {
	return k.queryBus
}

// GetEventStore returns the event store
func (k *CQRSKeeper) GetEventStore() CQRSEventStore {
	return k.eventStore
}

// ExecuteCommand executes a command
func (k *CQRSKeeper) ExecuteCommand(ctx context.Context, cmd CQRSCommand) error {
	if k == nil {
		return fmt.Errorf("keeper cannot be nil")
	}

	if k.commandBus == nil {
		return fmt.Errorf("command bus cannot be nil")
	}

	if ctx == nil {
		return fmt.Errorf("context cannot be nil")
	}

	if cmd == nil {
		return fmt.Errorf("command cannot be nil")
	}

	return k.commandBus.Execute(ctx, cmd)
}

// ExecuteQuery executes a query
func (k *CQRSKeeper) ExecuteQuery(ctx context.Context, qry CQRSQuery) (interface{}, error) {
	if k == nil {
		return nil, fmt.Errorf("keeper cannot be nil")
	}

	if k.queryBus == nil {
		return nil, fmt.Errorf("query bus cannot be nil")
	}

	if ctx == nil {
		return nil, fmt.Errorf("context cannot be nil")
	}

	if qry == nil {
		return nil, fmt.Errorf("query cannot be nil")
	}

	return k.queryBus.Execute(ctx, qry)
}
