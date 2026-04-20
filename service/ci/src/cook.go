package main

import (
	"context"
	"fmt"
)

// Cook prints compiler TODOs for CHIEF (mint not yet implemented).
func (m *Rice) Cook(ctx context.Context, project string) error {
	fmt.Printf("cook: TODO CHIEF — mint compiler for %s\n", project)
	return nil
}
