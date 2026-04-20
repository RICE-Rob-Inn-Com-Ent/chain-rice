package main

import (
	"context"
	"fmt"
)

// Prepare creates a minimal custom/{project} scaffold (CHIEF TODO: mint generator).
func (m *Rice) Prepare(ctx context.Context, project string) error {
	fmt.Printf("prepare: TODO CHIEF — scaffold custom/%s\n", project)
	return nil
}
